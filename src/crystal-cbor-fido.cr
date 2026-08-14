require "big"

module Crystal::Cbor::Fido
  VERSION = "0.1.1"

  alias Value = (Bool | Int64 | Float64 | String | Bytes | Array(Value) | Hash(Value, Value))?

  module SipHash
    class State
      property v0 : UInt64
      property v1 : UInt64
      property v2 : UInt64
      property v3 : UInt64

      def initialize(k0 : UInt64, k1 : UInt64)
        @v0 = k0 ^ 0x736f6d6570736575_u64
        @v1 = k1 ^ 0x646f72616e646f6d_u64
        @v2 = k0 ^ 0x6c7967656e657261_u64
        @v3 = k1 ^ 0x7465646279746573_u64
      end

      def compress
        @v0 &+= @v1
        @v1 = rotate_left(@v1, 13)
        @v1 ^= @v0
        @v0 = rotate_left(@v0, 32)
        @v2 &+= @v3
        @v3 = rotate_left(@v3, 16)
        @v3 ^= @v2
        @v0 &+= @v3
        @v3 = rotate_left(@v3, 21)
        @v3 ^= @v0
        @v2 &+= @v1
        @v1 = rotate_left(@v1, 17)
        @v1 ^= @v2
        @v2 = rotate_left(@v2, 32)
      end

      private def rotate_left(x : UInt64, n : Int32) : UInt64
        (x << n) | (x >> (64 - n))
      end
    end

    def self.siphash24(data : Bytes, key : Bytes) : UInt64
      raise "Key must be 16 bytes" unless key.size == 16

      k0 = read_u64_le(key, 0)
      k1 = read_u64_le(key, 8)

      state = State.new(k0, k1)

      i = 0
      while i + 8 <= data.size
        m = read_u64_le(data, i)
        state.v3 ^= m
        2.times { state.compress }
        state.v0 ^= m
        i += 8
      end

      m = finalization_block(data, i, data.size)
      state.v3 ^= m
      2.times { state.compress }
      state.v0 ^= m

      state.v2 ^= 0xff_u64
      4.times { state.compress }

      state.v0 ^ state.v1 ^ state.v2 ^ state.v3
    end

    private def self.read_u64_le(data : Bytes, offset : Int32) : UInt64
      result = 0_u64
      8.times do |j|
        result |= data[offset + j].to_u64 << (8 * j)
      end
      result
    end

    private def self.finalization_block(data : Bytes, start : Int32, total_len : Int32) : UInt64
      m = (total_len.to_u64 & 0xff) << 56

      rem = total_len - start
      case rem
      when 7
        m |= data[start + 6].to_u64 << 48
        m |= data[start + 5].to_u64 << 40
        m |= data[start + 4].to_u64 << 32
        m |= data[start + 3].to_u64 << 24
        m |= data[start + 2].to_u64 << 16
        m |= data[start + 1].to_u64 << 8
        m |= data[start].to_u64
      when 6
        m |= data[start + 5].to_u64 << 40
        m |= data[start + 4].to_u64 << 32
        m |= data[start + 3].to_u64 << 24
        m |= data[start + 2].to_u64 << 16
        m |= data[start + 1].to_u64 << 8
        m |= data[start].to_u64
      when 5
        m |= data[start + 4].to_u64 << 32
        m |= data[start + 3].to_u64 << 24
        m |= data[start + 2].to_u64 << 16
        m |= data[start + 1].to_u64 << 8
        m |= data[start].to_u64
      when 4
        m |= data[start + 3].to_u64 << 24
        m |= data[start + 2].to_u64 << 16
        m |= data[start + 1].to_u64 << 8
        m |= data[start].to_u64
      when 3
        m |= data[start + 2].to_u64 << 16
        m |= data[start + 1].to_u64 << 8
        m |= data[start].to_u64
      when 2
        m |= data[start + 1].to_u64 << 8
        m |= data[start].to_u64
      when 1
        m |= data[start].to_u64
      end

      m
    end
  end

  class SipHashSet
    @key : Bytes
    @buckets : Array(Array(Bytes))
    @size : Int32

    def initialize(initial_capacity = 16)
      @key = Random::Secure.random_bytes(16)
      @buckets = Array.new(initial_capacity) { [] of Bytes }
      @size = 0
    end

    def add(key : Bytes) : Bool
      hash = SipHash.siphash24(key, @key)
      bucket_idx = (hash % @buckets.size).to_i32

      bucket = @buckets[bucket_idx]

      bucket.each do |existing|
        return false if constant_time_equal(existing, key)
      end

      bucket << key.dup
      @size += 1

      rehash if @size > @buckets.size * 0.75

      true
    end

    def includes?(key : Bytes) : Bool
      hash = SipHash.siphash24(key, @key)
      bucket_idx = (hash % @buckets.size).to_i32

      @buckets[bucket_idx].each do |existing|
        return true if constant_time_equal(existing, key)
      end

      false
    end

    private def constant_time_equal(a : Bytes, b : Bytes) : Bool
      return false unless a.size == b.size
      result = 0_u8
      a.size.times { |i| result |= a[i] ^ b[i] }
      result == 0
    end

    private def rehash
      old_buckets = @buckets
      @buckets = Array.new(@buckets.size * 2) { [] of Bytes }
      @size = 0

      old_buckets.each do |bucket|
        bucket.each { |key| add(key) }
      end
    end
  end

  module Float16
    SIGN_MASK = 0x8000_u16
    EXP_MASK  = 0x7C00_u16
    MAN_MASK  = 0x03FF_u16
    EXP_BIAS  =         15

    EXP_MAX = 0x1F

    def self.from_float64(value : Float64) : UInt16
      if special = encode_special(value)
        return special
      end

      bits = value.unsafe_as(UInt64)
      sign = ((bits >> 63) & 1).to_u16
      exponent = ((bits >> 52) & 0x7FF).to_i32 - 1023
      mantissa = bits & 0xFFFFFFFFFFFFF_u64

      if exponent > 15
        (sign << 15 | 0x7C00).to_u16
      elsif exponent < -24
        (sign << 15).to_u16
      elsif exponent >= -14
        encode_normalized(sign, exponent, mantissa)
      else
        encode_subnormal(sign, exponent, mantissa)
      end
    end

    private def self.encode_special(value : Float64) : UInt16?
      if value.nan?
        0x7E00_u16
      elsif value.infinite?
        value > 0 ? 0x7C00_u16 : 0xFC00_u16
      elsif value == 0.0
        bits = value.unsafe_as(UInt64)
        sign = ((bits >> 63) & 1).to_u16
        (sign << 15).to_u16
      end
    end

    private def self.encode_normalized(sign : UInt16, exponent : Int32, mantissa : UInt64) : UInt16
      new_exp = exponent + 15
      new_man = ((mantissa >> 42) & 0x3FF).to_u16

      round_bit = (mantissa >> 41) & 1
      if round_bit == 1
        new_man += 1
        if new_man > 0x3FF
          new_man = 0
          new_exp += 1
        end
      end

      (sign << 15 | (new_exp.to_u16 << 10) | new_man).to_u16
    end

    private def self.encode_subnormal(sign : UInt16, exponent : Int32, mantissa : UInt64) : UInt16
      shift = -14 - exponent
      return (sign << 15).to_u16 if shift > 10

      subnormal_man = ((1_u64 << 52) | mantissa) >> (42 + shift)
      new_man = (subnormal_man & 0x3FF).to_u16
      (sign << 15 | new_man).to_u16
    end

    def self.to_float64(bits : UInt16) : Float64
      sign = (bits >> 15) & 1
      exponent = ((bits >> 10) & 0x1F).to_i32
      mantissa = (bits & 0x3FF).to_u64

      if exponent == 0x1F
        if mantissa == 0
          return sign == 0 ? Float64::INFINITY : -Float64::INFINITY
        else
          return Float64::NAN
        end
      end

      f64_sign = sign.to_u64 << 63

      if exponent == 0
        if mantissa == 0
          return sign == 0 ? 0.0 : -0.0
        end

        leading_zeros = 0
        temp = mantissa
        while temp < 0x200 && leading_zeros < 10
          temp <<= 1
          leading_zeros += 1
        end

        adjusted_exp = -14 - leading_zeros + 1
        normalized_man = (temp & 0x3FF) << (52 - 10 + leading_zeros - 1)

        f64_exp = ((adjusted_exp + 1023).to_u64 & 0x7FF) << 52
        f64_man = normalized_man
      else
        f64_exp = ((exponent - 15 + 1023).to_u64 & 0x7FF) << 52
        f64_man = mantissa << 42
      end

      (f64_sign | f64_exp | f64_man).unsafe_as(Float64)
    end

    def self.exactly_representable?(value : Float64) : Bool
      return true if value.nan? || value.infinite? || value == 0.0

      f16_bits = from_float64(value)
      back_to_f64 = to_float64(f16_bits)

      value == back_to_f64
    end
  end

  class Encoder
    MAX_DEPTH = 16

    @io : IO
    @depth : Int32

    def initialize(@io)
      @depth = 0
    end

    def encode(value : Value)
      @depth += 1
      raise "Max depth exceeded" if @depth > MAX_DEPTH

      begin
        case value
        when Nil     then encode_null
        when Bool    then encode_bool(value)
        when Int64   then encode_int(value)
        when Float64 then encode_float(value)
        when String  then encode_string(value)
        when Bytes   then encode_bytes(value)
        when Array   then encode_array(value)
        when Hash    then encode_map(value)
        end
      ensure
        @depth -= 1
      end
    end

    private def encode_null
      @io.write_byte(0xf6_u8)
    end

    private def encode_bool(b : Bool)
      @io.write_byte(b ? 0xf5_u8 : 0xf4_u8)
    end

    private def encode_int(i : Int64)
      if i >= 0
        encode_uint(i)
      else
        encode_negative(i)
      end
    end

    private def encode_uint(i : Int64)
      if i < 24
        @io.write_byte(i.to_u8)
      elsif i <= UInt8::MAX
        @io.write_byte(0x18_u8)
        @io.write_byte(i.to_u8)
      elsif i <= UInt16::MAX
        @io.write_byte(0x19_u8)
        @io.write_bytes(i.to_u16, IO::ByteFormat::BigEndian)
      elsif i <= UInt32::MAX
        @io.write_byte(0x1a_u8)
        @io.write_bytes(i.to_u32, IO::ByteFormat::BigEndian)
      else
        @io.write_byte(0x1b_u8)
        @io.write_bytes(i.to_u64, IO::ByteFormat::BigEndian)
      end
    end

    private def encode_negative(i : Int64)
      encoded = (-1_i128 - i.to_i128).to_u64

      if encoded < 24
        @io.write_byte(0x20_u8 | encoded.to_u8)
      elsif encoded <= UInt8::MAX
        @io.write_byte(0x38_u8)
        @io.write_byte(encoded.to_u8)
      elsif encoded <= UInt16::MAX
        @io.write_byte(0x39_u8)
        @io.write_bytes(encoded.to_u16, IO::ByteFormat::BigEndian)
      elsif encoded <= UInt32::MAX
        @io.write_byte(0x3a_u8)
        @io.write_bytes(encoded.to_u32, IO::ByteFormat::BigEndian)
      else
        @io.write_byte(0x3b_u8)
        @io.write_bytes(encoded, IO::ByteFormat::BigEndian)
      end
    end

    private def encode_float(f : Float64)
      if Float16.exactly_representable?(f)
        f16 = Float16.from_float64(f)
        @io.write_byte(0xf9_u8)
        @io.write_bytes(f16, IO::ByteFormat::BigEndian)
      elsif fits_in_float32_exactly?(f)
        @io.write_byte(0xfa_u8)
        @io.write_bytes(f.to_f32.unsafe_as(UInt32), IO::ByteFormat::BigEndian)
      else
        @io.write_byte(0xfb_u8)
        @io.write_bytes(f.unsafe_as(UInt64), IO::ByteFormat::BigEndian)
      end
    end

    private def fits_in_float32_exactly?(f : Float64) : Bool
      f32 = f.to_f32
      f32.to_f64 == f
    rescue OverflowError
      false
    end

    private def encode_string(s : String)
      bytes = s.to_slice
      write_bytes_header(bytes.size, 0x60_u8)
      @io.write(bytes)
    end

    private def encode_bytes(b : Bytes)
      write_bytes_header(b.size, 0x40_u8)
      @io.write(b)
    end

    private def write_bytes_header(len : Int32, base : UInt8)
      if len < 24
        @io.write_byte(base | len.to_u8)
      elsif len <= UInt8::MAX
        @io.write_byte(base | 0x18_u8)
        @io.write_byte(len.to_u8)
      elsif len <= UInt16::MAX
        @io.write_byte(base | 0x19_u8)
        @io.write_bytes(len.to_u16, IO::ByteFormat::BigEndian)
      elsif len <= UInt32::MAX
        @io.write_byte(base | 0x1a_u8)
        @io.write_bytes(len.to_u32, IO::ByteFormat::BigEndian)
      else
        @io.write_byte(base | 0x1b_u8)
        @io.write_bytes(len.to_u64, IO::ByteFormat::BigEndian)
      end
    end

    private def encode_array(arr : Array(Value))
      write_bytes_header(arr.size, 0x80_u8)
      arr.each { |v| encode(v) }
    end

    private def encode_map(map : Hash(Value, Value))
      sorted = map.to_a.sort do |val_a, val_b|
        bytes_a = canonical_key_bytes(val_a[0])
        bytes_b = canonical_key_bytes(val_b[0])

        cmp = bytes_a.size <=> bytes_b.size
        if cmp == 0
          bytes_a.size.times do |i|
            cmp = bytes_a[i] <=> bytes_b[i]
            break if cmp != 0
          end
        end
        cmp
      end

      write_bytes_header(sorted.size, 0xa0_u8)
      sorted.each do |k, v|
        encode(k)
        encode(v)
      end
    end

    private def canonical_key_bytes(key : Value) : Bytes
      io = IO::Memory.new
      Encoder.new(io).encode(key)
      io.to_slice
    end
  end

  class Decoder
    MAX_DEPTH =             16
    MAX_LEN   = 10_000_000_u64

    @io : IO
    @depth : Int32

    def initialize(@io)
      @depth = 0
    end

    def decode : Value
      @depth += 1
      raise "Max depth exceeded" if @depth > MAX_DEPTH

      begin
        byte = @io.read_byte
        raise "EOF" unless byte

        major = (byte >> 5) & 0x07
        additional = byte & 0x1f

        case major
        when 0 then decode_uint(additional)
        when 1 then decode_negative(additional)
        when 2 then decode_bytes(additional)
        when 3 then decode_string(additional)
        when 4 then decode_array(additional)
        when 5 then decode_map(additional)
        when 7 then decode_simple(additional)
        else
          raise "Unknown major type: #{major}"
        end
      ensure
        @depth -= 1
      end
    end

    private def decode_uint(additional : UInt8) : Int64
      val = read_additional(additional)
      if val > Int64::MAX
        raise "Integer overflow"
      else
        val.to_i64
      end
    end

    private def decode_negative(additional : UInt8) : Int64
      val = read_additional(additional)
      decoded = -1_i128 - val.to_i128
      if decoded < Int64::MIN
        raise "Integer underflow"
      else
        decoded.to_i64
      end
    end

    private def read_additional(additional : UInt8) : UInt64
      case additional
      when 0..23 then additional.to_u64
      when 24    then (@io.read_byte || raise "EOF").to_u64
      when 25    then @io.read_bytes(UInt16, IO::ByteFormat::BigEndian).to_u64
      when 26    then @io.read_bytes(UInt32, IO::ByteFormat::BigEndian).to_u64
      when 27    then @io.read_bytes(UInt64, IO::ByteFormat::BigEndian)
      else            raise "Invalid additional info: #{additional}"
      end
    end

    private def decode_bytes(additional : UInt8) : Bytes
      len = read_additional(additional)
      raise "Size too large" if len > MAX_LEN

      data = Bytes.new(len.to_i32)
      @io.read_fully(data)
      data
    end

    private def decode_string(additional : UInt8) : String
      String.new(decode_bytes(additional))
    end

    private def decode_array(additional : UInt8) : Array(Value)
      len = read_additional(additional)
      raise "Size too large" if len > MAX_LEN

      result = Array(Value).new(Math.min(len, 1024_u64).to_i32)
      len.times { result << decode }
      result
    end

    private def decode_map(additional : UInt8) : Hash(Value, Value)
      len = read_additional(additional)
      raise "Size too large" if len > MAX_LEN

      result = {} of Value => Value
      len.times do
        k = decode
        v = decode
        raise "Duplicate key in map" if result.has_key?(k)
        result[k] = v
      end
      result
    end

    private def decode_simple(additional : UInt8) : Value
      case additional
      when 20 then false
      when 21 then true
      when 22 then nil
      when 25 then Float16.to_float64(@io.read_bytes(UInt16, IO::ByteFormat::BigEndian))
      when 26 then @io.read_bytes(Float32, IO::ByteFormat::BigEndian).to_f64
      when 27 then @io.read_bytes(Float64, IO::ByteFormat::BigEndian)
      end
    end
  end
end
