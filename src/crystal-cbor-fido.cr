module Crystal::Cbor::Fido
  VERSION = "0.1.2"

  def self.encode(value : Value) : Bytes
    io = IO::Memory.new
    Encoder.new(io).encode(value)
    io.to_slice
  end

  def self.decode(bytes : Bytes) : Value
    Decoder.new(IO::Memory.new(bytes)).decode
  end
end

require "./crystal-cbor-fido/types"
require "./crystal-cbor-fido/float16"
require "./crystal-cbor-fido/encoder"
require "./crystal-cbor-fido/decoder"
