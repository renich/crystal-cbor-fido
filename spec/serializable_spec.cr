require "./spec_helper"

# Verifies [FUNC-006] / [TECH-006]
private struct SpecCoseEc2Key
  include CBOR::Serializable
  @[CBOR::Field(key: 1_i64)]
  getter kty : Int64
  @[CBOR::Field(key: 3_i64)]
  getter alg : Int64
  @[CBOR::Field(key: -1_i64)]
  getter crv : Int64
  @[CBOR::Field(key: -2_i64)]
  getter x : Bytes
  @[CBOR::Field(key: -3_i64)]
  getter y : Bytes

  def initialize(@kty : Int64, @alg : Int64, @crv : Int64, @x : Bytes, @y : Bytes) : Nil
  end
end

# Verifies [FUNC-006] / [TECH-006]
private struct SpecNestedRpEntity
  include Crystal::Cbor::Fido::Serializable
  getter id : String
  getter name : String?
  @[Crystal::Cbor::Fido::Field(ignore: true)]
  property cached_hash : String = "local-only"

  def initialize(@id : String, @name : String? = nil, @cached_hash : String = "local-only") : Nil
  end
end

# Verifies [FUNC-006] / [TECH-006]
private class SpecMakeCredentialArgs
  include CBOR::Serializable
  @[CBOR::Field(key: "client_hash")]
  getter client_data_hash : Bytes
  getter rp : SpecNestedRpEntity
  getter? rk : Bool
  getter uv_count : Int32
  getter counter : UInt64
  getter weight : Float64
  getter algorithms : Array(Int64)
  getter extensions : Hash(String, Bool)
  getter pin_auth : Bytes?

  def initialize(
    @client_data_hash : Bytes, @rp : SpecNestedRpEntity, @rk : Bool, @uv_count : Int32,
    @counter : UInt64, @weight : Float64, @algorithms : Array(Int64),
    @extensions : Hash(String, Bool), @pin_auth : Bytes? = nil,
  ) : Nil
  end
end

# Verifies [FUNC-006] / [TECH-006]
private struct SpecNarrowNumericPacket
  include CBOR::Serializable
  getter i8 : Int8
  getter i16 : Int16
  getter u8 : UInt8
  getter u16 : UInt16
  getter u32 : UInt32
  getter f32 : Float32

  def initialize(@i8 : Int8, @i16 : Int16, @u8 : UInt8, @u16 : UInt16, @u32 : UInt32, @f32 : Float32) : Nil
  end
end

# Verifies [FUNC-006] / [TECH-006]
@[CBOR::Serializable::Options(strict: false)]
private struct SpecNonStrictResponse
  include CBOR::Serializable
  @[CBOR::Field(key: 1_i64)]
  getter status : Int64
  @[CBOR::Field(key: "fmt")]
  getter fmt : String

  def initialize(@status : Int64, @fmt : String) : Nil
  end
end

# Verifies [FUNC-006] / [TECH-006]
describe Crystal::Cbor::Fido::Serializable do
  # Verifies [FUNC-006] / [TECH-006]
  describe "TASK-201 & TASK-202: CBOR::Field and CBOR::Serializable Synthesis" do
    it "serializes integer-keyed COSE keys in canonical CTAP2 key order and round-trips" do
      x_coord = Bytes.new(32, 0xaa_u8)
      y_coord = Bytes.new(32, 0xbb_u8)
      key = SpecCoseEc2Key.new(kty: 2_i64, alg: -7_i64, crv: 1_i64, x: x_coord, y: y_coord)

      bytes = key.to_cbor
      bytes[0].should eq(0xa5_u8)
      bytes[1].should eq(0x01_u8)
      bytes[3].should eq(0x03_u8)
      bytes[5].should eq(0x20_u8)

      decoded = SpecCoseEc2Key.from_cbor(bytes)
      decoded.kty.should eq(2_i64)
      decoded.alg.should eq(-7_i64)
      decoded.crv.should eq(1_i64)
      decoded.x.should eq(x_coord)
      decoded.y.should eq(y_coord)
    end

    it "supports nested Serializable types, primitives, Array, Hash, nilable fields, and ignore: true" do
      rp = SpecNestedRpEntity.new(id: "evalinux.com", name: "EVALinux", cached_hash: "custom-secret")
      args = SpecMakeCredentialArgs.new(
        client_data_hash: Bytes[1, 2, 3, 4], rp: rp, rk: true, uv_count: 42,
        counter: 18_446_744_073_709_551_615_u64, weight: 1.5,
        algorithms: [-7_i64, -8_i64, -257_i64],
        extensions: {"hmac-secret" => true, "credProtect" => false}, pin_auth: nil
      )

      io = IO::Memory.new
      args.to_cbor(io)
      io.rewind

      restored = SpecMakeCredentialArgs.from_cbor(io)
      restored.client_data_hash.should eq(Bytes[1, 2, 3, 4])
      restored.rp.id.should eq("evalinux.com")
      restored.rp.name.should eq("EVALinux")
      restored.rp.cached_hash.should eq("local-only")
      restored.rk?.should be_true
      restored.uv_count.should eq(42)
      restored.counter.should eq(18_446_744_073_709_551_615_u64)
      restored.weight.should eq(1.5)
      restored.algorithms.should eq([-7_i64, -8_i64, -257_i64])
      restored.extensions.should eq({"hmac-secret" => true, "credProtect" => false})
      restored.pin_auth.should be_nil
    end

    it "round-trips narrower numeric fields and rejects out-of-range values with CborError" do
      pkt = SpecNarrowNumericPacket.new(
        i8: -128_i8, i16: 32_767_i16, u8: 255_u8, u16: 65_535_u16, u32: 4_000_000_000_u32, f32: 3.25_f32
      )
      restored = SpecNarrowNumericPacket.from_cbor(pkt.to_cbor)
      restored.should eq(pkt)
      pkt.to_cbor_value.as(Hash(CBOR::Value, CBOR::Value))["u8"].should eq(255_u64)

      expect_raises(CBOR::CborError, /Int8 overflow/) { CBOR::Codec.from_cbor_value(Int8, 128_i64) }
      expect_raises(CBOR::CborError, /Int16 overflow/) { CBOR::Codec.from_cbor_value(Int16, -32_769_i64) }
      expect_raises(CBOR::CborError, /UInt8 overflow/) { CBOR::Codec.from_cbor_value(UInt8, 256_i64) }
      expect_raises(CBOR::CborError, /non-negative UInt16/) { CBOR::Codec.from_cbor_value(UInt16, -1_i64) }
      expect_raises(CBOR::CborError, /UInt16 overflow/) { CBOR::Codec.from_cbor_value(UInt16, 65_536_u64) }
      expect_raises(CBOR::CborError, /UInt32 overflow/) { CBOR::Codec.from_cbor_value(UInt32, 4_294_967_296_i64) }
      expect_raises(CBOR::CborError, /Float32 overflow/) { CBOR::Codec.from_cbor_value(Float32, 1.0e+100) }
    end

    it "rejects unknown map keys by default when strict: true" do
      map = {
        1_i64 => 2_i64, 3_i64 => -7_i64, 99_i64 => "unexpected",
        -1_i64 => 1_i64, -2_i64 => Bytes[1], -3_i64 => Bytes[2],
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value
      encoded = Crystal::Cbor::Fido.encode(map)

      expect_raises(Crystal::Cbor::Fido::CborError, /Unknown CBOR field/) do
        SpecCoseEc2Key.from_cbor(encoded)
      end
    end

    it "skips unknown keys when strict: false while still enforcing canonical key ordering" do
      map = {
        1_i64 => 0_i64, 99_i64 => "extra-extension", "fmt" => "packed", "unknown" => true,
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value
      encoded = Crystal::Cbor::Fido.encode(map)

      resp = SpecNonStrictResponse.from_cbor(encoded)
      resp.status.should eq(0_i64)
      resp.fmt.should eq("packed")
    end

    it "unconditionally raises CanonicalError on duplicate map keys in both strict and non-strict modes" do
      dup_bytes = Bytes[0xa3, 0x01, 0x00, 0x01, 0x02, 0x63, 0x66, 0x6d, 0x74, 0x66, 0x70, 0x61, 0x63, 0x6b, 0x65, 0x64]

      expect_raises(Crystal::Cbor::Fido::CanonicalError, /Duplicate key/) do
        SpecNonStrictResponse.from_cbor(dup_bytes)
      end

      expect_raises(Crystal::Cbor::Fido::CanonicalError, /Duplicate key/) do
        SpecCoseEc2Key.from_cbor(dup_bytes)
      end
    end

    it "raises CanonicalError on unsorted map keys even when strict: false" do
      unsorted = Bytes[0xa2, 0x63, 0x66, 0x6d, 0x74, 0x64, 0x6e, 0x6f, 0x6e, 0x65, 0x01, 0x00]
      expect_raises(Crystal::Cbor::Fido::CanonicalError, /sorted order/) do
        SpecNonStrictResponse.from_cbor(unsorted)
      end
    end

    it "raises CborError on missing required fields or type mismatches" do
      partial_map = {1_i64 => 0_i64} of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value
      incomplete = Crystal::Cbor::Fido.encode(partial_map)
      expect_raises(Crystal::Cbor::Fido::CborError, /Missing required CBOR field/) do
        SpecNonStrictResponse.from_cbor(incomplete)
      end

      wrong_type = CBOR.encode({1_i64 => "not-an-int", "fmt" => "packed"} of CBOR::Value => CBOR::Value)
      expect_raises(Crystal::Cbor::Fido::CborError, /Expected Int64/) do
        SpecNonStrictResponse.from_cbor(wrong_type)
      end
    end
  end
end
