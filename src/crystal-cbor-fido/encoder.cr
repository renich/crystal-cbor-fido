module Crystal::Cbor::Fido
  # Serializes Crystal `Value` objects into deterministic FIDO2/CTAP2 Canonical CBOR.
  class Encoder
    MAX_DEPTH = 16

    # Represents a pre-encoded map entry used for canonical key sorting and duplicate detection.
    record MapEntry, key_bytes : Bytes, key : Value, value : Value do
      include Comparable(MapEntry)

      # Compares two map entries by their canonical key byte representations.
      def <=>(other : MapEntry) : Int32
        Crystal::Cbor::Fido.compare_canonical_bytes(key_bytes, other.key_bytes)
      end
    end

    @io : IO
    @depth : Int32

    # Creates a new `Encoder` writing to *io* starting at nesting *depth*.
    def initialize(@io : IO, @depth : Int32 = 0) : Nil
    end

    # Encodes *value* to the underlying `IO`, enforcing `MAX_DEPTH` and canonical map sorting.
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

    private def encode_null : Nil
      @io.write_byte(0xf6_u8)
    end

    private def encode_bool(b : Bool) : Nil
      @io.write_byte(b ? 0xf5_u8 : 0xf4_u8)
    end

    private def encode_int(i : Int64) : Nil
      if i >= 0
        encode_uint(i.to_u64)
      else
        encode_negative(i)
      end
    end

    private def encode_uint(i : UInt64) : Nil
      write_type_and_arg(0x00_u8, i)
    end

    private def encode_negative(i : Int64) : Nil
      encoded = (-1_i128 - i.to_i128).to_u64
      write_type_and_arg(0x20_u8, encoded)
    end

    private def encode_float(f : Float64) : Nil
      case
      when Float16.exactly_representable?(f)
        f16 = Float16.from_float64(f)
        @io.write_byte(0xf9_u8)
        @io.write_bytes(f16, IO::ByteFormat::BigEndian)
      when Crystal::Cbor::Fido.fits_in_float32_exactly?(f)
        @io.write_byte(0xfa_u8)
        @io.write_bytes(f.to_f32.unsafe_as(UInt32), IO::ByteFormat::BigEndian)
      else
        @io.write_byte(0xfb_u8)
        @io.write_bytes(f.unsafe_as(UInt64), IO::ByteFormat::BigEndian)
      end
    end

    private def encode_string(s : String) : Nil
      bytes = s.to_slice
      write_type_and_arg(0x60_u8, bytes.size.to_u64)
      @io.write(bytes)
    end

    private def encode_bytes(b : Bytes) : Nil
      write_type_and_arg(0x40_u8, b.size.to_u64)
      @io.write(b)
    end

    private def write_type_and_arg(major_base : UInt8, value : UInt64) : Nil
      case value
      when 0_u64..23_u64
        @io.write_byte(major_base | value.to_u8)
      when 24_u64..UInt8::MAX.to_u64
        @io.write_byte(major_base | 0x18_u8)
        @io.write_byte(value.to_u8)
      when (UInt8::MAX.to_u64 + 1)..UInt16::MAX.to_u64
        @io.write_byte(major_base | 0x19_u8)
        @io.write_bytes(value.to_u16, IO::ByteFormat::BigEndian)
      when (UInt16::MAX.to_u64 + 1)..UInt32::MAX.to_u64
        @io.write_byte(major_base | 0x1a_u8)
        @io.write_bytes(value.to_u32, IO::ByteFormat::BigEndian)
      else
        @io.write_byte(major_base | 0x1b_u8)
        @io.write_bytes(value, IO::ByteFormat::BigEndian)
      end
    end

    private def encode_array(arr : Array(Value)) : Nil
      write_type_and_arg(0x80_u8, arr.size.to_u64)
      arr.each { |item| encode(item) }
    end

    private def encode_map(map : Hash(Value, Value)) : Nil
      entries = Array(MapEntry).new(map.size)
      map.each do |key, val|
        entries << MapEntry.new(canonical_key_bytes(key), key, val)
      end

      entries.sort!
      (0...(entries.size - 1)).each do |idx|
        if entries[idx].key_bytes == entries[idx + 1].key_bytes
          raise CanonicalError.new("Duplicate key in canonical CBOR map")
        end
      end

      write_type_and_arg(0xa0_u8, entries.size.to_u64)
      entries.each do |entry|
        @io.write(entry.key_bytes)
        encode(entry.value)
      end
    end

    private def canonical_key_bytes(key : Value) : Bytes
      mem = IO::Memory.new
      Encoder.new(mem, @depth).encode(key)
      mem.to_slice
    end
  end
end
