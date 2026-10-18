# Canonical CBOR (RFC 8949 Section 4.2 / FIDO2 CTAP2 Section 6) encoder and decoder.
module Crystal::Cbor::Fido
  VERSION = "0.2.0"

  # Encodes *value* into its deterministic Canonical CBOR byte representation.
  def self.encode(value : Value) : Bytes
    io = IO::Memory.new
    Encoder.new(io).encode(value)
    io.to_slice
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
require "./crystal-cbor-fido/encoder"
require "./crystal-cbor-fido/decoder"
