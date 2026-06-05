require "./spec_helper"
require "big"

describe Crystal::Cbor::Fido do
  describe "Coverage - SipHash" do
    it "covers remaining rem blocks in finalization" do
      key = Bytes.new(16, 0)
      # Sizes 1 to 7 to cover rem=1..7
      (1..7).each do |size|
        Crystal::Cbor::Fido::SipHash.siphash24(Bytes.new(size, 0xaa), key).should be_a(UInt64)
      end
    end
  end

  describe "Coverage - SipHashSet" do
    it "handles constant_time_equal edge cases" do
      set = Crystal::Cbor::Fido::SipHashSet.new(2)
      set.add(Bytes[1, 2, 3]).should be_true

      # Different size
      set.includes?(Bytes[1, 2]).should be_false

      # Same size, different content
      set.includes?(Bytes[1, 2, 4]).should be_false
    end
  end

  describe "Coverage - Float16" do
    it "handles subnormal floats in from_float64 and to_float64" do
      # Smallest positive subnormal: 2**-24
      val = Crystal::Cbor::Fido::Float16.from_float64(2.0 ** -24)
      val.should eq(0x0001_u16)
      Crystal::Cbor::Fido::Float16.to_float64(val).should eq(2.384185791015625e-7)

      # A regular subnormal
      val2 = Crystal::Cbor::Fido::Float16.from_float64(2.0 ** -15)
      val2.should eq(0x0200_u16)
      Crystal::Cbor::Fido::Float16.to_float64(val2).should eq(0.000152587890625)
    end

    it "handles negative subnormal floats" do
      val = Crystal::Cbor::Fido::Float16.from_float64(-(2.0 ** -24))
      val.should eq(0x8001_u16)
      Crystal::Cbor::Fido::Float16.to_float64(val).should eq(-2.384185791015625e-7)
    end

    it "handles Float16.to_float64 NaN" do
      # NaN with mantissa != 0
      Crystal::Cbor::Fido::Float16.to_float64(0x7FFF_u16).nan?.should be_true
    end

    it "handles from_float64 subnormal underflow" do
      val = Crystal::Cbor::Fido::Float16.from_float64(2.0 ** -26)
      val.should eq(0x0000_u16)
    end
  end

  describe "Coverage - Encoder/Decoder" do
    it "handles large unsigned integers" do
      vals = [24_i64, 255_i64, 256_i64, 65535_i64, 65536_i64, 4294967295_i64, 4294967296_i64]
      vals.each do |v|
        io = IO::Memory.new
        enc = Crystal::Cbor::Fido::Encoder.new(io)
        enc.encode(v)
        io.rewind
        dec = Crystal::Cbor::Fido::Decoder.new(io)
        dec.decode.should eq(v)
      end
    end

    it "handles negative integers" do
      vals = [-1_i64, -24_i64, -25_i64, -256_i64, -65536_i64, -4294967296_i64, -4294967297_i64]
      vals.each do |v|
        io = IO::Memory.new
        enc = Crystal::Cbor::Fido::Encoder.new(io)
        enc.encode(v)
        io.rewind
        dec = Crystal::Cbor::Fido::Decoder.new(io)
        dec.decode.should eq(v)
      end
    end

    it "handles Float32 and Float64 in encoder and decoder" do
      # Note: 0.1 is not exactly representable in Float16, but might be exactly representable in Float32 or Float64.
      io = IO::Memory.new
      enc = Crystal::Cbor::Fido::Encoder.new(io)

      f32_val = 1234.567_f32.to_f64
      enc.encode(f32_val)
      io.rewind
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.should eq(f32_val)

      io.clear
      f64_val = Float64::MAX
      enc.encode(f64_val)
      io.rewind
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.should eq(f64_val)
    end

    it "handles arrays and strings with lengths requiring 1, 2, 4, 8 bytes" do
      io = IO::Memory.new
      enc = Crystal::Cbor::Fido::Encoder.new(io)

      # Array size 24
      arr24 = Array.new(24) { 0_i64.as(Crystal::Cbor::Fido::Value) }
      enc.encode(arr24)
      io.rewind
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.as(Array).size.should eq(24)

      # String size 256
      io.clear
      str256 = "a" * 256
      enc.encode(str256)
      io.rewind
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.should eq(str256)

      # Bytes size 65536
      io.clear
      bytes65536 = Bytes.new(65536, 0x01_u8)
      enc.encode(bytes65536)
      io.rewind
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.as(Bytes).size.should eq(65536)
    end

    it "handles decoder edge cases like EOF and unknown additional info" do
      io = IO::Memory.new(Bytes.empty)
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Exception, "EOF") { dec.decode }

      # Bad major type: major type 6 (tags) is not implemented in our simple decoder
      io = IO::Memory.new(Bytes[0xc0])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Exception, "Unknown major type: 6") { dec.decode }

      # Bad additional info 28
      io = IO::Memory.new(Bytes[0x1c])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Exception, "Invalid additional info: 28") { dec.decode }

      # EOF in middle of string
      io = IO::Memory.new(Bytes[0x62, 0x61]) # length 2, but only 1 byte present
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(IO::EOFError) { dec.decode }
    end

    it "decodes simple values correctly" do
      io = IO::Memory.new(Bytes[0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0x1f])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.should be_false
      dec.decode.should be_true
      dec.decode.should be_nil

      dec.decode.should be_nil
    end
  end
end
