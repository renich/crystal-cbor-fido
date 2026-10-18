module Crystal::Cbor::Fido
  # Byte-counting `IO` wrapper that enforces a strict upper limit on consumed stream bytes.
  class BoundedIO < IO
    # Total number of bytes read from the underlying stream.
    getter bytes_read : UInt64

    # Maximum allowed bytes to read from the underlying stream.
    getter max_bytes : UInt64

    # Wraps *io* with a hard read ceiling of *max_bytes*.
    def initialize(@io : IO, @max_bytes : UInt64) : Nil
      @bytes_read = 0_u64
    end

    # Reads up to `slice.size` bytes while enforcing `max_bytes`.
    def read(slice : Bytes) : Int32
      return 0 if slice.empty?

      remaining = @max_bytes - @bytes_read
      if remaining == 0
        return 0 unless trailing_bytes?
        raise CborError.new("Stream byte limit of #{@max_bytes} exceeded")
      end

      max_chunk = Math.min(slice.size.to_u64, remaining).to_i32
      count = @io.read(slice[0, max_chunk])
      @bytes_read += count.to_u64

      if count == max_chunk && max_chunk < slice.size && trailing_bytes?
        raise CborError.new("Stream byte limit of #{@max_bytes} exceeded")
      end

      count
    end

    # Writing to a `BoundedIO` decoder stream is unsupported.
    def write(slice : Bytes) : NoReturn
      raise IO::Error.new("BoundedIO is read-only")
    end

    # Returns `true` if the underlying `IO` contains at least one unconsumed trailing byte.
    def trailing_bytes? : Bool
      if peeked = @io.peek
        return !peeked.empty?
      end
      !@io.read_byte.nil?
    end
  end
end
