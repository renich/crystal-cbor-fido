require "./spec_helper"

describe Crystal::Cbor::Fido do
  describe "Float16 Subnormal and Edge Case Coverage" do
    it "handles subnormal floats in from_float64 and to_float64" do
      # Smallest positive subnormal: 2**-24
      val = Crystal::Cbor::Fido::Float16.from_float64(2.0 ** -24)
      val.should eq(0x0001_u16)
      Crystal::Cbor::Fido::Float16.to_float64(val).should eq(5.960_464_477_539_062_5e-8)

      # A regular subnormal
      val2 = Crystal::Cbor::Fido::Float16.from_float64(2.0 ** -15)
      val2.should eq(0x0200_u16)
      Crystal::Cbor::Fido::Float16.to_float64(val2).should eq(0.000_030_517_578_125)
    end

    it "handles negative subnormal floats" do
      val = Crystal::Cbor::Fido::Float16.from_float64(-(2.0 ** -24))
      val.should eq(0x8001_u16)
      Crystal::Cbor::Fido::Float16.to_float64(val).should eq(-5.960_464_477_539_062_5e-8)
    end

    it "handles Float16.to_float64 NaN" do
      Crystal::Cbor::Fido::Float16.to_float64(0x7FFF_u16).nan?.should be_true
    end

    it "handles from_float64 subnormal underflow" do
      val = Crystal::Cbor::Fido::Float16.from_float64(2.0 ** -26)
      val.should eq(0x0000_u16)
    end
  end

  describe "Encoder/Decoder Numeric Coverage" do
    it "handles large unsigned integers" do
      vals = [24_i64, 255_i64, 256_i64, 65_535_i64, 65_536_i64, 4_294_967_295_i64, 4_294_967_296_i64]
      vals.each do |val|
        encoded = Crystal::Cbor::Fido.encode(val)
        Crystal::Cbor::Fido.decode(encoded).should eq(val)
      end
    end

    it "handles negative integers" do
      vals = [-1_i64, -24_i64, -25_i64, -256_i64, -65_536_i64, -4_294_967_296_i64, -4_294_967_297_i64]
      vals.each do |val|
        encoded = Crystal::Cbor::Fido.encode(val)
        Crystal::Cbor::Fido.decode(encoded).should eq(val)
      end
    end

    it "handles Float32 and Float64 in encoder and decoder" do
      f32_val = 1234.567_f32.to_f64
      encoded_f32 = Crystal::Cbor::Fido.encode(f32_val)
      Crystal::Cbor::Fido.decode(encoded_f32).should eq(f32_val)

      f64_val = Float64::MAX
      encoded_f64 = Crystal::Cbor::Fido.encode(f64_val)
      Crystal::Cbor::Fido.decode(encoded_f64).should eq(f64_val)
    end
  end

  describe "Decoder Edge Cases and Bounds" do
    it "handles decoder edge cases like EOF and unknown additional info" do
      io = IO::Memory.new(Bytes.empty)
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Crystal::Cbor::Fido::CborError, /EOF/) { dec.decode }

      # Bad major type: major type 6 (tags)
      io = IO::Memory.new(Bytes[0xc0])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Crystal::Cbor::Fido::CborError, /Unknown major type: 6/) { dec.decode }

      # Bad additional info 28
      io = IO::Memory.new(Bytes[0x1c])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      expect_raises(Crystal::Cbor::Fido::CborError, /Invalid or reserved additional info: 28/) { dec.decode }
    end

    it "decodes simple values correctly" do
      io = IO::Memory.new(Bytes[0xf4, 0xf5, 0xf6])
      dec = Crystal::Cbor::Fido::Decoder.new(io)
      dec.decode.should be_false
      dec.decode.should be_true
      dec.decode.should be_nil
    end
  end
end
