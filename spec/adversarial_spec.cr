require "./spec_helper"

describe "Adversarial Code Review - CBOR FIDO" do
  describe "Depth Bounds" do
    it "prevents infinite recursion in Encoder" do
      arr = Array(Crystal::Cbor::Fido::Value).new
      current = arr
      17.times do
        next_arr = Array(Crystal::Cbor::Fido::Value).new
        current << next_arr
        current = next_arr
      end

      io = IO::Memory.new
      encoder = Crystal::Cbor::Fido::Encoder.new(io)
      expect_raises(Crystal::Cbor::Fido::DepthError, /Max nesting depth/) do
        encoder.encode(arr)
      end
    end

    it "prevents stack overflow in Decoder" do
      io = IO::Memory.new
      17.times do
        io.write_byte(0x81_u8) # Array of length 1
      end
      io.write_byte(0x01_u8) # integer 1
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Crystal::Cbor::Fido::DepthError, /Max nesting depth/) do
        decoder.decode
      end
    end
  end

  describe "Allocation bounds" do
    it "prevents OOM on huge string allocations" do
      io = IO::Memory.new
      # string major type 3, additional 26 (32-bit minimal length for 10_000_001)
      io.write_byte(0x7a_u8)
      io.write_bytes(10_000_001_u32, IO::ByteFormat::BigEndian)
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Crystal::Cbor::Fido::CborError, /Size too large/) do
        decoder.decode
      end
    end

    it "prevents OOM on huge array allocations" do
      io = IO::Memory.new
      # array major type 4, additional 26 (32-bit minimal length for 10_000_001)
      io.write_byte(0x9a_u8)
      io.write_bytes(10_000_001_u32, IO::ByteFormat::BigEndian)
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Crystal::Cbor::Fido::CborError, /Array length too large/) do
        decoder.decode
      end
    end

    it "prevents cumulative allocation budget exceeding MAX_LEN across nested containers" do
      io = IO::Memory.new
      io.write_byte(0x82_u8) # Array of 2 (allocates 2)
      io.write_byte(0x5a_u8) # Byte string of 10_000_000 bytes (total 10_000_002 > MAX_LEN)
      io.write_bytes(10_000_000_u32, IO::ByteFormat::BigEndian)
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Crystal::Cbor::Fido::CborError, /Total allocation size exceeds/) do
        decoder.decode
      end
    end
  end

  describe "FIDO Canonical Map Encoding & Duplicates" do
    it "sorts keys by length then lexicographically" do
      map = {
        "aa" => 1_i64,
        "z"  => 2_i64,
        "a"  => 3_i64,
        "b"  => 4_i64,
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value

      bytes = Crystal::Cbor::Fido.encode(map)
      bytes[0].should eq(0xa4_u8)

      # Raw sequential reading to verify wire order
      decoder_io = IO::Memory.new(bytes)
      decoder_io.read_byte # skip 0xa4
      dec2 = Crystal::Cbor::Fido::Decoder.new(decoder_io)
      dec2.decode.should eq("a")
      dec2.decode # value 3
      dec2.decode.should eq("b")
      dec2.decode # value 4
      dec2.decode.should eq("z")
      dec2.decode # value 2
      dec2.decode.should eq("aa")
    end

    it "rejects duplicate canonical keys when encoding map" do
      map = Hash(Crystal::Cbor::Fido::Value, Crystal::Cbor::Fido::Value).new
      map[Float64::NAN] = 1_i64
      map[Float64::NAN] = 2_i64

      expect_raises(Crystal::Cbor::Fido::CanonicalError, /Duplicate key in canonical CBOR map/) do
        Crystal::Cbor::Fido.encode(map)
      end
    end

    it "rejects duplicate keys when decoding map" do
      io = IO::Memory.new
      io.write_byte(0xa2_u8) # Map of length 2
      # key 1: "a"
      io.write_byte(0x61_u8)
      io.write_byte(0x61_u8)
      io.write_byte(0x01_u8) # val 1
      # key 2: "a" (duplicate)
      io.write_byte(0x61_u8)
      io.write_byte(0x61_u8)
      io.write_byte(0x02_u8) # val 2
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Crystal::Cbor::Fido::CanonicalError, /Duplicate key/) do
        decoder.decode
      end
    end
  end

  describe "Float16 decoding" do
    it "decodes float16 correctly" do
      io = IO::Memory.new
      io.write_byte(0xf9_u8) # Float16
      io.write_bytes(0x3e00_u16, IO::ByteFormat::BigEndian)
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      val = decoder.decode
      val.should be_a(Float64)
      val.should eq(1.5)
    end
  end
end
