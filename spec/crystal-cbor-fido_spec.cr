require "./spec_helper"

describe Crystal::Cbor::Fido do
  describe "Float16 Precision & IEEE 754 Conformance" do
    it "handles zero and negative zero" do
      Crystal::Cbor::Fido::Float16.from_float64(0.0).should eq(0x0000_u16)
      Crystal::Cbor::Fido::Float16.from_float64(-0.0).should eq(0x8000_u16)
      Crystal::Cbor::Fido::Float16.to_float64(0x0000_u16).should eq(0.0)
      Crystal::Cbor::Fido::Float16.to_float64(0x8000_u16).should eq(-0.0)
    end

    it "handles infinity and NaN" do
      Crystal::Cbor::Fido::Float16.from_float64(Float64::INFINITY).should eq(0x7C00_u16)
      Crystal::Cbor::Fido::Float16.from_float64(-Float64::INFINITY).should eq(0xFC00_u16)
      Crystal::Cbor::Fido::Float16.from_float64(Float64::NAN).should eq(0x7E00_u16)

      Crystal::Cbor::Fido::Float16.to_float64(0x7C00_u16).should eq(Float64::INFINITY)
      Crystal::Cbor::Fido::Float16.to_float64(0xFC00_u16).should eq(-Float64::INFINITY)
      Crystal::Cbor::Fido::Float16.to_float64(0x7E00_u16).nan?.should be_true
    end

    it "decodes subnormal Float16 mathematically without precision corruption" do
      # Smallest positive subnormal: 1 * 2^-24 = 5.9604644775390625e-8
      bits = 0x0001_u16
      expected = 5.9604644775390625e-8
      Crystal::Cbor::Fido::Float16.to_float64(bits).should eq(expected)

      # Subnormal 2^-15 = 0.000030517578125 (0x0200)
      sub_bits = 0x0200_u16
      Crystal::Cbor::Fido::Float16.to_float64(sub_bits).should eq(0.000030517578125)
    end

    it "encodes subnormal Float16 numbers with round-to-nearest-even" do
      val = 5.9604644775390625e-8
      Crystal::Cbor::Fido::Float16.from_float64(val).should eq(0x0001_u16)
    end
  end

  describe "Canonical CBOR Encoding (RFC 8949 / CTAP2)" do
    it "encodes primitives (null, booleans)" do
      Crystal::Cbor::Fido.encode(nil).hexstring.should eq("f6")
      Crystal::Cbor::Fido.encode(true).hexstring.should eq("f5")
      Crystal::Cbor::Fido.encode(false).hexstring.should eq("f4")
    end

    it "encodes unsigned integers minimally" do
      Crystal::Cbor::Fido.encode(10_i64).hexstring.should eq("0a")
      Crystal::Cbor::Fido.encode(100_i64).hexstring.should eq("1864")
      Crystal::Cbor::Fido.encode(1000_i64).hexstring.should eq("1903e8")
      Crystal::Cbor::Fido.encode(100000_i64).hexstring.should eq("1a000186a0")
    end

    it "encodes full 64-bit unsigned integers" do
      u = 18446744073709551615_u64 # UInt64::MAX
      encoded = Crystal::Cbor::Fido.encode(u)
      encoded.hexstring.should eq("1bffffffffffffffff")
      Crystal::Cbor::Fido.decode(encoded).should eq(u)
    end

    it "encodes maps with canonical sorting (shorter key first, then byte-wise)" do
      map = {
        "aa" => 2_i64,
        "a"  => 1_i64,
        "bb" => 3_i64,
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value

      bytes = Crystal::Cbor::Fido.encode(map)
      bytes.hexstring.should eq("a36161016261610262626203")
    end
  end

  describe "Canonical CBOR Decoding Strictness" do
    it "decodes valid canonically encoded maps" do
      map = {
        "a"  => 1_i64,
        "aa" => 2_i64,
        "bb" => 3_i64,
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value

      bytes = Crystal::Cbor::Fido.encode(map)
      decoded = Crystal::Cbor::Fido.decode(bytes)
      decoded.should eq(map)
    end

    it "rejects non-minimal 1-byte integer encodings" do
      # 0x18 0x05 is 5 encoded as 2 bytes instead of 0x05
      non_minimal = Bytes[0x18, 0x05]
      expect_raises(Crystal::Cbor::Fido::CanonicalError, /Non-minimal/) do
        Crystal::Cbor::Fido.decode(non_minimal)
      end
    end

    it "rejects non-minimal 2-byte integer encodings" do
      # 0x19 0x00 0x10 is 16 encoded as 3 bytes instead of 0x10
      non_minimal = Bytes[0x19, 0x00, 0x10]
      expect_raises(Crystal::Cbor::Fido::CanonicalError, /Non-minimal/) do
        Crystal::Cbor::Fido.decode(non_minimal)
      end
    end

    it "rejects maps with unsorted keys" do
      # Map of 2 entries: key "b" before "a" (unsorted)
      unsorted_map = Bytes[0xa2, 0x61, 0x62, 0x01, 0x61, 0x61, 0x02]
      expect_raises(Crystal::Cbor::Fido::CanonicalError, /sorted order/) do
        Crystal::Cbor::Fido.decode(unsorted_map)
      end
    end

    it "rejects maps with duplicate keys" do
      # Map of 2 entries: key "a" then "a"
      duplicate_map = Bytes[0xa2, 0x61, 0x61, 0x01, 0x61, 0x61, 0x02]
      expect_raises(Crystal::Cbor::Fido::CanonicalError, /Duplicate key/) do
        Crystal::Cbor::Fido.decode(duplicate_map)
      end
    end

    it "rejects undefined simple value 23" do
      # 0xf7 is simple 23 (undefined)
      expect_raises(Crystal::Cbor::Fido::CanonicalError, /undefined.*forbidden/) do
        Crystal::Cbor::Fido.decode(Bytes[0xf7])
      end
    end

    it "rejects invalid UTF-8 string encoding" do
      # String of 2 bytes with invalid continuation
      invalid_utf8 = Bytes[0x62, 0xc0, 0xaf]
      expect_raises(Crystal::Cbor::Fido::CborError, /Invalid UTF-8/) do
        Crystal::Cbor::Fido.decode(invalid_utf8)
      end
    end
  end
end
