module Crystal::Cbor::Fido
  # Deserializes FIDO2/CTAP2 Canonical CBOR payloads with strict canonicality and allocation bounds enforcement.
  class Decoder
    MAX_DEPTH =             16
    MAX_LEN   = 10_000_000_u64

    @io : IO
    @depth : Int32
    @total_allocated : UInt64

    # Creates a new `Decoder` reading from *io*.
    def initialize(@io : IO) : Nil
      @depth = 0
      @total_allocated = 0_u64
    end

    # Reads and validates the next CBOR data item from the underlying `IO`.
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
        val = read_u16_be.to_u64
        if val <= UInt8::MAX
          raise CanonicalError.new("Non-minimal 2-byte encoding: #{val} must be encoded in 1 byte")
        end
        val
      when 26
        val = read_u32_be.to_u64
        if val <= UInt16::MAX
          raise CanonicalError.new("Non-minimal 4-byte encoding: #{val} must be encoded in 2 bytes")
        end
        val
      when 27
        val = read_u64_be
        if val <= UInt32::MAX
          raise CanonicalError.new("Non-minimal 8-byte encoding: #{val} must be encoded in 4 bytes")
        end
        val
      else
        raise CborError.new("Invalid or reserved additional info: #{additional}")
      end
    end

    private def track_allocation(len : UInt64, max_msg : String) : Nil
      raise CborError.new(max_msg) if len > MAX_LEN
      raise CborError.new("Total allocation size exceeds #{MAX_LEN}") if @total_allocated + len > MAX_LEN
      @total_allocated += len
    end

    private def decode_bytes(additional : UInt8) : Bytes
      len = read_additional(additional)
      track_allocation(len, "Size too large: #{len} > #{MAX_LEN}")

      data = Bytes.new(len.to_i32)
      read_exact(data)
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
      track_allocation(len, "Array length too large: #{len} > #{MAX_LEN}")

      result = Array(Value).new(Math.min(len, 1024_u64).to_i32)
      len.times { result << decode }
      result
    end

    private def decode_map(additional : UInt8) : Hash(Value, Value)
      len = read_additional(additional)
      track_allocation(len, "Map length too large: #{len} > #{MAX_LEN}")

      result = Hash(Value, Value).new(initial_capacity: Math.min(len, 1024_u64).to_i32)
      prev_key_bytes : Bytes? = nil

      len.times do
        k = decode
        k_bytes = canonical_key_bytes(k)
        verify_key_order(prev_key_bytes, k_bytes)
        prev_key_bytes = k_bytes
        result[k] = decode
      end
      result
    end

    private def verify_key_order(prev : Bytes?, current : Bytes) : Nil
      return unless prev
      cmp = Crystal::Cbor::Fido.compare_canonical_bytes(prev, current)
      return if cmp < 0
      raise CanonicalError.new("Duplicate key in canonical CBOR map") if cmp == 0
      raise CanonicalError.new("Keys in canonical CBOR map are not in sorted order")
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
      when 25 then decode_float16
      when 26 then decode_float32
      when 27 then decode_float64
      else
        raise CborError.new("Invalid or reserved simple value: #{additional}")
      end
    end

    private def decode_float16 : Float64
      bits = read_u16_be
      val = Float16.to_float64(bits)
      raise CanonicalError.new("Non-canonical Float16 NaN encoding") if val.nan? && bits != 0x7e00_u16
      val
    end

    private def decode_float32 : Float64
      val = read_f32_be.to_f64
      if val.nan? || Float16.exactly_representable?(val)
        raise CanonicalError.new("Non-minimal Float32 encoding")
      end
      val
    end

    private def decode_float64 : Float64
      val = read_f64_be
      if val.nan? || Float16.exactly_representable?(val) || Crystal::Cbor::Fido.fits_in_float32_exactly?(val)
        raise CanonicalError.new("Non-minimal Float64 encoding")
      end
      val
    end

    private def read_u16_be : UInt16
      @io.read_bytes(UInt16, IO::ByteFormat::BigEndian)
    rescue IO::EOFError
      raise CborError.new("Unexpected EOF")
    end

    private def read_u32_be : UInt32
      @io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
    rescue IO::EOFError
      raise CborError.new("Unexpected EOF")
    end

    private def read_u64_be : UInt64
      @io.read_bytes(UInt64, IO::ByteFormat::BigEndian)
    rescue IO::EOFError
      raise CborError.new("Unexpected EOF")
    end

    private def read_f32_be : Float32
      @io.read_bytes(Float32, IO::ByteFormat::BigEndian)
    rescue IO::EOFError
      raise CborError.new("Unexpected EOF")
    end

    private def read_f64_be : Float64
      @io.read_bytes(Float64, IO::ByteFormat::BigEndian)
    rescue IO::EOFError
      raise CborError.new("Unexpected EOF")
    end

    private def read_exact(slice : Bytes) : Nil
      @io.read_fully(slice)
    rescue IO::EOFError
      raise CborError.new("Unexpected EOF")
    end

    private def canonical_key_bytes(key : Value) : Bytes
      mem = IO::Memory.new
      Encoder.new(mem, @depth).encode(key)
      mem.to_slice
    end
  end
end
