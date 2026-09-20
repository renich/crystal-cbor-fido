module Crystal::Cbor::Fido
  class CborError < Exception
  end

  class CanonicalError < CborError
  end

  class DepthError < CborError
  end

  alias Value = (Bool | Int64 | UInt64 | Float64 | String | Bytes | Array(Value) | Hash(Value, Value))?
end
