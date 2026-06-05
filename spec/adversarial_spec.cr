require "./spec_helper"
require "../src/crystal-cbor-fido"

describe "Adversarial Code Review - CBOR FIDO" do
  describe "Depth Bounds" do
    it "prevents infinite recursion in Encoder" do
      # Create a self-referential array?
      # Crystal arrays are strictly typed, but we can bypass or just nest deeply
      arr = [] of Crystal::Cbor::Fido::Value
      current = arr
      17.times do
        next_arr = [] of Crystal::Cbor::Fido::Value
        current << next_arr
        current = next_arr
      end

      io = IO::Memory.new
      encoder = Crystal::Cbor::Fido::Encoder.new(io)
      expect_raises(Exception, "Max depth exceeded") do
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
      expect_raises(Exception, "Max depth exceeded") do
        decoder.decode
      end
    end
  end

  describe "Allocation bounds" do
    it "prevents OOM on huge string allocations" do
      io = IO::Memory.new
      # string major type 3, additional 27 (64-bit length)
      io.write_byte(0x7b_u8)
      io.write_bytes(10_000_001_u64, IO::ByteFormat::BigEndian)
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Exception, "Size too large") do
        decoder.decode
      end
    end

    it "prevents OOM on huge array allocations" do
      io = IO::Memory.new
      # array major type 4, additional 27
      io.write_byte(0x9b_u8)
      io.write_bytes(10_000_001_u64, IO::ByteFormat::BigEndian)
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Exception, "Size too large") do
        decoder.decode
      end
    end
  end

  describe "FIDO Canonical Map Encoding & Duplicates" do
    it "sorts keys by length then lexicographically" do
      # FIDO map keys should be sorted.
      map = {
        "aa" => 1_i64,
        "z"  => 2_i64,
        "a"  => 3_i64,
        "b"  => 4_i64,
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value

      io = IO::Memory.new
      encoder = Crystal::Cbor::Fido::Encoder.new(io)
      encoder.encode(map)

      # Expect order: "a", "b", "z", "aa"
      # a (type 3, len 1) = 0x61, 0x61
      # b = 0x61, 0x62
      # z = 0x61, 0x7a
      # aa = 0x62, 0x61, 0x61
      io.rewind
      bytes = io.to_slice
      # It's a map of 4 (0xa4)
      bytes[0].should eq(0xa4_u8)

      # verify keys decoded in sequence
      # bypassing decode_map to read raw sequential to verify order
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
      expect_raises(Exception, "Duplicate key in map") do
        decoder.decode
      end
    end
  end

  describe "Float16 decoding" do
    it "decodes float16 correctly" do
      io = IO::Memory.new
      # Float16 1.5 -> sign 0, exp 15 (bias) + 0, man 10_0000_0000 -> 0x3e00
      io.write_byte(0xf9_u8) # Float16
      io.write_bytes(0x3e00_u16, IO::ByteFormat::BigEndian)
      io.rewind

      decoder = Crystal::Cbor::Fido::Decoder.new(io)
      val = decoder.decode
      val.should be_a(Float64)
      val.should eq(1.5)
    end
  end

  describe "SipHashSet" do
    it "adds without collisions and handles boundary safely" do
      set = Crystal::Cbor::Fido::SipHashSet.new(2)
      set.add("a".to_slice).should be_true
      set.add("b".to_slice).should be_true
      set.add("c".to_slice).should be_true
      set.add("a".to_slice).should be_false

      set.includes?("a".to_slice).should be_true
      set.includes?("d".to_slice).should be_false
    end
  end
end
