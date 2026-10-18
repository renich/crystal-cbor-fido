# Canonical CBOR (RFC 8949 Section 4.2 / FIDO2 CTAP2 Section 6) encoder and decoder.
module Crystal::Cbor::Fido
  # Current semantic version of the `crystal-cbor-fido` shard.
  VERSION = "0.2.2"

  # Encodes *value* into its deterministic Canonical CBOR byte representation.
  def self.encode(value : Value) : Bytes
    io = IO::Memory.new
    Encoder.new(io).encode(value)
    io.to_slice
  end

  # Encodes *value* directly to *io* in Canonical CBOR format, enforcing *max_depth*.
  def self.encode(value : Value, io : IO, max_depth : Int32 = Encoder::MAX_DEPTH) : Nil
    Encoder.encode(value, io, max_depth: max_depth)
  end

  # Encodes a `Serializable` object into its Canonical CBOR byte representation.
  def self.encode(value : Serializable) : Bytes
    value.to_cbor
  end

  # Encodes a `Serializable` object directly to *io* in Canonical CBOR format.
  def self.encode(value : Serializable, io : IO, max_depth : Int32 = Encoder::MAX_DEPTH) : Nil
    value.to_cbor(io, max_depth: max_depth)
  end

  # Decodes a Canonical CBOR byte slice into a `Value`, rejecting non-canonical encodings and trailing bytes.
  def self.decode(bytes : Bytes) : Value
    io = IO::Memory.new(bytes)
    value = Decoder.new(io).decode
    if io.pos != bytes.size
      raise CanonicalError.new("Trailing bytes after top-level CBOR item: #{bytes.size - io.pos} unconsumed")
    end
    value
  end

  # Decodes a Canonical CBOR data item from *io* with bounded depth, byte budget, and optional EOF verification.
  def self.decode(
    io : IO,
    max_depth : Int32 = Decoder::MAX_DEPTH,
    max_bytes : UInt64 = Decoder::DEFAULT_STREAM_MAX_BYTES,
    eof_check : Bool = true,
  ) : Value
    Decoder.decode(io, max_depth: max_depth, max_bytes: max_bytes, eof_check: eof_check)
  end

  # Compares two canonical CBOR byte slices using CTAP2 canonical ordering
  # (shorter byte length first, then lexicographical byte order).
  def self.compare_canonical_bytes(a : Bytes, b : Bytes) : Int32
    cmp = a.size <=> b.size
    cmp != 0 ? cmp : (a <=> b)
  end

  # Returns `true` if *value* can be losslessly represented as an IEEE 754 single-precision float (`Float32`).
  def self.fits_in_float32_exactly?(value : Float64) : Bool
    f32 = value.to_f32
    f32.to_f64 == value
  rescue OverflowError
    false
  end
end

require "./crystal-cbor-fido/types"
require "./crystal-cbor-fido/float16"
require "./crystal-cbor-fido/bounded_io"
require "./crystal-cbor-fido/encoder"
require "./crystal-cbor-fido/decoder"
require "./crystal-cbor-fido/serializable"
