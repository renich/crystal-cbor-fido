module Crystal::Cbor::Fido
  # Base exception raised for malformed CBOR structures or bounds violations.
  class CborError < Exception
  end

  # Raised when a CBOR payload violates RFC 8949 Section 4.2 or CTAP2 Canonical CBOR encoding rules.
  class CanonicalError < CborError
  end

  # Raised when CBOR container nesting exceeds `Encoder::MAX_DEPTH` or `Decoder::MAX_DEPTH`.
  class DepthError < CborError
  end

  # Recursive union of all Crystal types supported in a FIDO Canonical CBOR data item.
  alias Value = (Bool | Int64 | UInt64 | Float64 | String | Bytes | Array(Value) | Hash(Value, Value))?
end
