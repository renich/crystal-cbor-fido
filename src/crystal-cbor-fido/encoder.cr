module Crystal::Cbor::Fido
  class Encoder
    MAX_DEPTH = 16

    record MapEntry, key_bytes : Bytes, key : Value, value : Value do
      include Comparable(MapEntry)

      def <=>(other : MapEntry) : Int32
        cmp = key_bytes.size <=> other.key_bytes.size
        return cmp unless cmp == 0
        key_bytes.size.times do |i|
          diff = key_bytes[i].to_i32 - other.key_bytes[i].to_i32
          return diff <=> 0 unless diff == 0
        end
        0
      end
    end

    @io : IO
    @depth : Int32

    def initialize(@io : IO)
      @depth = 0
    end

    def encode(value : Value) : Nil
      @depth += 1
      raise DepthError.new("Max nesting depth of #{MAX_DEPTH} exceeded") if @depth > MAX_DEPTH

      begin
        case value
        when Nil     then encode_null
        when Bool    then encode_bool(value)
        when Int64   then encode_int(value)
        when UInt64  then encode_uint(value)
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
        encode_uint(i.to_u64)
      else
        encode_negative(i)
      end
    end

    private def encode_uint(i : UInt64)
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
        @io.write_bytes(i, IO::ByteFormat::BigEndian)
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
      entries = Array(MapEntry).new(map.size)
      map.each do |key, val|
        entries << MapEntry.new(canonical_key_bytes(key), key, val)
      end

      entries.sort!

      write_bytes_header(entries.size, 0xa0_u8)
      entries.each do |entry|
        encode(entry.key)
        encode(entry.value)
      end
    end

    private def canonical_key_bytes(key : Value) : Bytes
      mem = IO::Memory.new
      Encoder.new(mem).encode(key)
      mem.to_slice
    end
  end
end
