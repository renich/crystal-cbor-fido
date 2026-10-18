module Crystal::Cbor::Fido
  # Deserializes FIDO2/CTAP2 Canonical CBOR payloads with strict canonicality and allocation bounds enforcement.
  class Decoder
    # Maximum allowed container nesting depth per CTAP2 canonical profile.
    MAX_DEPTH = 16

    # Absolute maximum cumulative allocation budget (10 MB) for a decode session.
    MAX_LEN = 10_000_000_u64

    # Default streaming byte budget (1 MiB) for `Decoder.decode(io)`.
    DEFAULT_STREAM_MAX_BYTES = 1_048_576_u64

    @io : IO
    @depth : Int32
    @max_depth : Int32
    @max_len : UInt64
    @total_allocated : UInt64

    # Decodes a single Canonical CBOR data item from *io* with configurable depth, byte, and EOF guards.
    def self.decode(
      io : IO,
      max_depth : Int32 = MAX_DEPTH,
      max_bytes : UInt64 = DEFAULT_STREAM_MAX_BYTES,
      eof_check : Bool = true,
    ) : Value
      effective_max = Math.min(max_bytes, MAX_LEN)
      bounded = BoundedIO.new(io, effective_max)
      decoder = new(bounded, max_depth: max_depth, max_len: effective_max)
      value = decoder.decode
      raise CanonicalError.new("Trailing bytes after top-level CBOR item") if eof_check && bounded.trailing_bytes?
      value
    end

    # Creates a new `Decoder` reading from *io* with configurable *max_depth* and *max_len* ceilings.
    def initialize(@io : IO, @max_depth : Int32 = MAX_DEPTH, @max_len : UInt64 = MAX_LEN) : Nil
      raise DepthError.new("Max nesting depth of #{MAX_DEPTH} exceeded") if @max_depth <= 0 || @max_depth > MAX_DEPTH
      @depth = 0
      @total_allocated = 0_u64
    end

    # Reads and validates the next CBOR data item from the underlying `IO`.
    def decode : Value
      @depth += 1
      raise DepthError.new("Max nesting depth of #{@max_depth} exceeded") if @depth > @max_depth

      begin
        byte = @io.read_byte || raise CborError.new("Unexpected EOF reading CBOR token")
        dispatch_major((byte >> 5) & 0x07_u8, byte & 0x1f_u8)
      ensure
        @depth -= 1
      end
    end

    private def dispatch_major(major : UInt8, additional : UInt8) : Value
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
    end

    private def decode_uint(additional : UInt8) : (Int64 | UInt64)
      val = read_additional(additional)
      val <= Int64::MAX.to_u64 ? val.to_i64 : val
    end

    private def decode_negative(additional : UInt8) : Int64
      val = read_additional(additional)
      decoded = -1_i128 - val.to_i128
      raise CborError.new("Integer underflow") if decoded < Int64::MIN
      decoded.to_i64
    end

    private def read_additional(additional : UInt8) : UInt64
      case additional
      when 0..23
        additional.to_u64
      when 24
        val = (@io.read_byte || raise CborError.new("Unexpected EOF")).to_u64
        verify_minimal_uint(val, 24_u64, "1-byte")
      when 25
        verify_minimal_uint(read_scalar(UInt16).to_u64, 0x100_u64, "2-byte")
      when 26
        verify_minimal_uint(read_scalar(UInt32).to_u64, 0x10000_u64, "4-byte")
      when 27
        verify_minimal_uint(read_scalar(UInt64), 0x100000000_u64, "8-byte")
      else
        raise CborError.new("Invalid or reserved additional info: #{additional}")
      end
    end

    private def verify_minimal_uint(val : UInt64, min_inclusive : UInt64, label : String) : UInt64
      raise CanonicalError.new("Non-minimal #{label} encoding: #{val}") if val < min_inclusive
      val
    end

    private def track_allocation(len : UInt64, max_msg : String) : Nil
      raise CborError.new(max_msg) if len > @max_len
      raise CborError.new("Total allocation size exceeds #{@max_len}") if @total_allocated + len > @max_len
      @total_allocated += len
    end

    private def decode_bytes(additional : UInt8) : Bytes
      len = read_additional(additional)
      track_allocation(len, "Size too large: #{len} > #{@max_len}")

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
      track_allocation(len, "Array length too large: #{len} > #{@max_len}")

      result = Array(Value).new(Math.min(len, 1024_u64).to_i32)
      len.times { result << decode }
      result
    end

    private def decode_map(additional : UInt8) : Hash(Value, Value)
      len = read_additional(additional)
      track_allocation(len, "Map length too large: #{len} > #{@max_len}")

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
      when 23 then raise CanonicalError.new("CBOR undefined (simple 23) is forbidden in canonical CBOR")
      when 24 then decode_simple_byte
      when 25 then decode_float16
      when 26 then decode_float32
      when 27 then decode_float64
      else
        raise CborError.new("Invalid or reserved simple value: #{additional}")
      end
    end

    private def decode_simple_byte : NoReturn
      val = @io.read_byte || raise CborError.new("Unexpected EOF")
      raise CanonicalError.new("Non-minimal simple value: #{val}") if val < 32
      raise CborError.new("Unsupported simple value: #{val}")
    end

    private def decode_float16 : Float64
      bits = read_scalar(UInt16)
      val = Float16.to_float64(bits)
      raise CanonicalError.new("Non-canonical Float16 NaN encoding") if val.nan? && bits != 0x7e00_u16
      val
    end

    private def decode_float32 : Float64
      val = read_scalar(Float32).to_f64
      raise CanonicalError.new("Non-minimal Float32 encoding") if val.nan? || Float16.exactly_representable?(val)
      val
    end

    private def decode_float64 : Float64
      val = read_scalar(Float64)
      non_min = val.nan? || Float16.exactly_representable?(val) || Crystal::Cbor::Fido.fits_in_float32_exactly?(val)
      raise CanonicalError.new("Non-minimal Float64 encoding") if non_min
      val
    end

    private def read_scalar(type : T.class) : T forall T
      @io.read_bytes(T, IO::ByteFormat::BigEndian)
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
      Encoder.new(mem, @depth, @max_depth).encode(key)
      mem.to_slice
    end
  end
end
