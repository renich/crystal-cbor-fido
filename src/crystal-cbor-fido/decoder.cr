module Crystal::Cbor::Fido
  class Decoder
    MAX_DEPTH =             16
    MAX_LEN   = 10_000_000_u64

    @io : IO
    @depth : Int32

    def initialize(@io : IO)
      @depth = 0
    end

    def decode : Value
      @depth += 1
      raise DepthError.new("Max nesting depth of #{MAX_DEPTH} exceeded") if @depth > MAX_DEPTH

      begin
        byte = @io.read_byte
        raise CborError.new("Unexpected EOF reading CBOR token") unless byte

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
          raise CborError.new("Unknown major type: #{major}")
        end
      ensure
        @depth -= 1
      end
    end

    private def decode_uint(additional : UInt8) : (Int64 | UInt64)
      val = read_additional(additional)
      val <= Int64::MAX.to_u64 ? val.to_i64 : val
    end

    private def decode_negative(additional : UInt8) : Int64
      val = read_additional(additional)
      decoded = -1_i128 - val.to_i128
      if decoded < Int64::MIN
        raise CborError.new("Integer underflow")
      end
      decoded.to_i64
    end

    private def read_additional(additional : UInt8) : UInt64
      case additional
      when 0..23
        additional.to_u64
      when 24
        val = (@io.read_byte || raise CborError.new("Unexpected EOF")).to_u64
        if val < 24
          raise CanonicalError.new("Non-minimal 1-byte encoding: #{val} must be encoded in header")
        end
        val
      when 25
        val = @io.read_bytes(UInt16, IO::ByteFormat::BigEndian).to_u64
        if val <= UInt8::MAX
          raise CanonicalError.new("Non-minimal 2-byte encoding: #{val} must be encoded in 1 byte")
        end
        val
      when 26
        val = @io.read_bytes(UInt32, IO::ByteFormat::BigEndian).to_u64
        if val <= UInt16::MAX
          raise CanonicalError.new("Non-minimal 4-byte encoding: #{val} must be encoded in 2 bytes")
        end
        val
      when 27
        val = @io.read_bytes(UInt64, IO::ByteFormat::BigEndian)
        if val <= UInt32::MAX
          raise CanonicalError.new("Non-minimal 8-byte encoding: #{val} must be encoded in 4 bytes")
        end
        val
      else
        raise CborError.new("Invalid or reserved additional info: #{additional}")
      end
    end

    private def decode_bytes(additional : UInt8) : Bytes
      len = read_additional(additional)
      raise CborError.new("Size too large: #{len} > #{MAX_LEN}") if len > MAX_LEN

      data = Bytes.new(len.to_i32)
      @io.read_fully(data)
      data
    end

    private def decode_string(additional : UInt8) : String
      bytes = decode_bytes(additional)
      str = String.new(bytes)
      raise CborError.new("Invalid UTF-8 string encoding") unless str.valid_encoding?
      str
    end

    private def decode_array(additional : UInt8) : Array(Value)
      len = read_additional(additional)
      raise CborError.new("Array length too large: #{len} > #{MAX_LEN}") if len > MAX_LEN

      result = Array(Value).new(Math.min(len, 1024_u64).to_i32)
      len.times { result << decode }
      result
    end

    private def decode_map(additional : UInt8) : Hash(Value, Value)
      len = read_additional(additional)
      raise CborError.new("Map length too large: #{len} > #{MAX_LEN}") if len > MAX_LEN

      result = Hash(Value, Value).new(initial_capacity: Math.min(len, 1024_u64).to_i32)
      prev_key_bytes : Bytes? = nil

      len.times do
        k = decode
        k_bytes = canonical_key_bytes(k)

        if prev = prev_key_bytes
          cmp = compare_canonical_keys(prev, k_bytes)
          if cmp >= 0
            if cmp == 0
              raise CanonicalError.new("Duplicate key in canonical CBOR map")
            else
              raise CanonicalError.new("Keys in canonical CBOR map are not in sorted order")
            end
          end
        end
        prev_key_bytes = k_bytes

        v = decode
        result[k] = v
      end
      result
    end

    private def decode_simple(additional : UInt8) : Value
      case additional
      when 20 then false
      when 21 then true
      when 22 then nil
      when 23
        raise CanonicalError.new("CBOR undefined (simple 23) is forbidden in canonical CBOR")
      when 24
        val = @io.read_byte || raise CborError.new("Unexpected EOF")
        if val < 32
          raise CanonicalError.new("Non-minimal simple value: #{val}")
        end
        raise CborError.new("Unsupported simple value: #{val}")
      when 25
        Float16.to_float64(@io.read_bytes(UInt16, IO::ByteFormat::BigEndian))
      when 26
        @io.read_bytes(Float32, IO::ByteFormat::BigEndian).to_f64
      when 27
        @io.read_bytes(Float64, IO::ByteFormat::BigEndian)
      else
        raise CborError.new("Invalid or reserved simple value: #{additional}")
      end
    end

    private def compare_canonical_keys(a : Bytes, b : Bytes) : Int32
      cmp = a.size <=> b.size
      return cmp unless cmp == 0
      a.size.times do |i|
        diff = a[i].to_i32 - b[i].to_i32
        return diff <=> 0 unless diff == 0
      end
      0
    end

    private def canonical_key_bytes(key : Value) : Bytes
      mem = IO::Memory.new
      Encoder.new(mem).encode(key)
      mem.to_slice
    end
  end
end
