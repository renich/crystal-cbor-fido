require "./spec_helper"
require "big"

describe Crystal::Cbor::Fido do
  describe "SipHash" do
    it "correctly hashes an empty string with the test vector key" do
      key = Bytes[0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f]
      data = Bytes.empty
      # Test vector for SipHash-2-4 with empty string and test key is 0x726fdb47dd0e0e31
      result = Crystal::Cbor::Fido::SipHash.siphash24(data, key)
      result.should eq(0x726fdb47dd0e0e31_u64)
    end

    it "raises on invalid key length" do
      expect_raises(Exception, "Key must be 16 bytes") do
        Crystal::Cbor::Fido::SipHash.siphash24(Bytes.empty, Bytes.new(15))
      end
    end

    it "hashes single byte and multiple bytes consistently" do
      key = Bytes[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
      # Some standard test vector comparisons can be added by junior dev
      result = Crystal::Cbor::Fido::SipHash.siphash24(Bytes[0x00], key)
      result.should be_a(UInt64)

      result64 = Crystal::Cbor::Fido::SipHash.siphash24(Bytes.new(64, 0xAA), key)
      result64.should be_a(UInt64)
      result64.should_not eq(result)
    end
  end

  describe "SipHashSet" do
    it "adds items and prevents duplicates" do
      set = Crystal::Cbor::Fido::SipHashSet.new(16)
      set.add(Bytes[1, 2, 3]).should be_true
      set.includes?(Bytes[1, 2, 3]).should be_true

      # Should return false on duplicate
      set.add(Bytes[1, 2, 3]).should be_false

      # Different item should be true
      set.add(Bytes[1, 2, 4]).should be_true
    end

    it "handles rehashing when capacity is reached" do
      set = Crystal::Cbor::Fido::SipHashSet.new(4)
      10.times do |i|
        set.add(Bytes[i.to_u8]).should be_true
      end
      # All items should still be included
      10.times do |i|
        set.includes?(Bytes[i.to_u8]).should be_true
      end
    end
  end

  describe "Float16" do
    it "handles zero and negative zero" do
      Crystal::Cbor::Fido::Float16.from_float64(0.0).should eq(0x0000_u16)
      Crystal::Cbor::Fido::Float16.from_float64(-0.0).should eq(0x8000_u16)
    end

    it "handles infinity and NaN" do
      Crystal::Cbor::Fido::Float16.from_float64(Float64::INFINITY).should eq(0x7C00_u16)
      Crystal::Cbor::Fido::Float16.from_float64(-Float64::INFINITY).should eq(0xFC00_u16)
      Crystal::Cbor::Fido::Float16.from_float64(Float64::NAN).should eq(0x7E00_u16)
    end

    it "converts normal floats" do
      Crystal::Cbor::Fido::Float16.from_float64(1.0).should eq(0x3C00_u16)
      Crystal::Cbor::Fido::Float16.from_float64(-1.0).should eq(0xBC00_u16)
      # Max Float16 = 65504.0
      Crystal::Cbor::Fido::Float16.from_float64(65504.0).should eq(0x7BFF_u16)
    end

    it "determines exact representability" do
      Crystal::Cbor::Fido::Float16.exactly_representable?(1.0).should be_true
      Crystal::Cbor::Fido::Float16.exactly_representable?(0.333333).should be_false
    end

    it "converts Float16 back to Float64 correctly" do
      val = Crystal::Cbor::Fido::Float16.from_float64(1.5)
      Crystal::Cbor::Fido::Float16.to_float64(val).should eq(1.5)
    end
  end

  describe "Encoder" do
    it "encodes primitives (null, booleans)" do
      io = IO::Memory.new
      enc = Crystal::Cbor::Fido::Encoder.new(io)

      enc.encode(nil)
      io.to_slice.hexstring.should eq("f6")

      io.clear
      enc.encode(true)
      io.to_slice.hexstring.should eq("f5")

      io.clear
      enc.encode(false)
      io.to_slice.hexstring.should eq("f4")
    end

    it "encodes unsigned integers minimally" do
      io = IO::Memory.new
      enc = Crystal::Cbor::Fido::Encoder.new(io)

      enc.encode(10_i64)
      io.to_slice.hexstring.should eq("0a")

      io.clear
      enc.encode(100_i64)
      io.to_slice.hexstring.should eq("1864")

      io.clear
      enc.encode(1000_i64)
      io.to_slice.hexstring.should eq("1903e8")
    end

    it "encodes strings and bytes" do
      io = IO::Memory.new
      enc = Crystal::Cbor::Fido::Encoder.new(io)

      enc.encode("a")
      io.to_slice.hexstring.should eq("6161")

      io.clear
      enc.encode(Bytes[0x01, 0x02])
      io.to_slice.hexstring.should eq("420102")
    end

    it "encodes arrays" do
      io = IO::Memory.new
      enc = Crystal::Cbor::Fido::Encoder.new(io)

      enc.encode([1_i64, 2_i64] of Crystal::Cbor::Fido::Value)
      io.to_slice.hexstring.should eq("820102")
    end

    it "encodes maps with canonical sorting (shortest key first, then lexicographical)" do
      io = IO::Memory.new
      enc = Crystal::Cbor::Fido::Encoder.new(io)

      # Maps should be sorted by length first, then byte-wise.
      map = {
        "aa" => 2_i64,
        "a"  => 1_i64,
        "bb" => 3_i64,
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value

      enc.encode(map)
      # a (61) -> 1 (01)
      # aa (626161) -> 2 (02)
      # bb (626262) -> 3 (03)
      # Map header: a3
      io.to_slice.hexstring.should eq("a36161016261610262626203")
    end
  end

  describe "Decoder" do
    it "decodes integers" do
      io = IO::Memory.new(Bytes[0x0a])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.should eq(10_i64)
    end

    it "decodes strings" do
      io = IO::Memory.new(Bytes[0x61, 0x61])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.should eq("a")
    end

    it "decodes simple maps" do
      io = IO::Memory.new(Bytes[0xa1, 0x61, 0x61, 0x01])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      result = dec.decode
      result.should be_a(Hash(Crystal::Cbor::Fido::Value, Crystal::Cbor::Fido::Value))
      if result.is_a?(Hash)
        result["a"].should eq(1_i64)
      end
    end
  end
end
