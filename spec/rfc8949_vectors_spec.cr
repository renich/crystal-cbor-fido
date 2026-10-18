require "./spec_helper"

# Verifies [FUNC-007] / [TECH-007]
describe "Phase 2 Streaming IO Codec & RFC 8949 Appendix A Vectors" do
  # Verifies [FUNC-007] / [TECH-007]
  describe "TASK-203: Bounded Streaming IO Codec" do
    it "encodes and decodes directly over IO streams with default bounds" do
      io = IO::Memory.new
      payload = {
        1_i64 => "ctap2",
        2_i64 => [true, 1.5, Bytes[0xde, 0xad]] of Crystal::Cbor::Fido::Value,
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value

      Crystal::Cbor::Fido::Encoder.encode(payload, io)
      io.rewind

      decoded = Crystal::Cbor::Fido::Decoder.decode(io)
      decoded.should eq(payload)
    end

    it "supports multi-frame sequential stream decoding when eof_check is false" do
      io = IO::Memory.new
      Crystal::Cbor::Fido.encode(42_i64, io)
      Crystal::Cbor::Fido.encode("second-frame", io)
      Crystal::Cbor::Fido.encode([1_i64, 2_i64] of Crystal::Cbor::Fido::Value, io)
      io.rewind

      Crystal::Cbor::Fido.decode(io, eof_check: false).should eq(42_i64)
      Crystal::Cbor::Fido.decode(io, eof_check: false).should eq("second-frame")
      Crystal::Cbor::Fido.decode(io, eof_check: true).should eq([1_i64, 2_i64] of Crystal::Cbor::Fido::Value)
    end

    it "raises CanonicalError on trailing bytes when eof_check is true" do
      io = IO::Memory.new
      Crystal::Cbor::Fido.encode(10_i64, io)
      Crystal::Cbor::Fido.encode(20_i64, io)
      io.rewind

      expect_raises(Crystal::Cbor::Fido::CanonicalError, /Trailing bytes/) do
        Crystal::Cbor::Fido.decode(io, eof_check: true)
      end
    end

    it "enforces custom max_depth on streaming encode and decode" do
      inner = ["deep".as(Crystal::Cbor::Fido::Value)] of Crystal::Cbor::Fido::Value
      mid = [inner.as(Crystal::Cbor::Fido::Value)] of Crystal::Cbor::Fido::Value
      nested = [mid.as(Crystal::Cbor::Fido::Value)] of Crystal::Cbor::Fido::Value
      out_io = IO::Memory.new

      expect_raises(Crystal::Cbor::Fido::DepthError, /Max nesting depth/) do
        Crystal::Cbor::Fido::Encoder.encode(nested, out_io, max_depth: 2)
      end

      valid_bytes = Crystal::Cbor::Fido.encode(nested)
      expect_raises(Crystal::Cbor::Fido::DepthError, /Max nesting depth/) do
        Crystal::Cbor::Fido::Decoder.decode(IO::Memory.new(valid_bytes), max_depth: 2)
      end

      expect_raises(Crystal::Cbor::Fido::DepthError, /Max nesting depth/) do
        Crystal::Cbor::Fido::Decoder.decode(IO::Memory.new(valid_bytes), max_depth: 32)
      end
    end

    it "enforces custom max_bytes on streaming decode for both declared and consumed bytes" do
      large_bytes = Crystal::Cbor::Fido.encode(Bytes.new(256, 0xaa_u8))
      expect_raises(Crystal::Cbor::Fido::CborError, /exceed|too large/) do
        Crystal::Cbor::Fido::Decoder.decode(IO::Memory.new(large_bytes), max_bytes: 64_u64)
      end

      arr = Array(Crystal::Cbor::Fido::Value).new(5, 1000_i64.as(Crystal::Cbor::Fido::Value))
      encoded_arr = Crystal::Cbor::Fido.encode(arr)
      expect_raises(Crystal::Cbor::Fido::CborError, /Stream byte limit/) do
        Crystal::Cbor::Fido::Decoder.decode(IO::Memory.new(encoded_arr), max_bytes: 10_u64)
      end
    end

    it "succeeds when max_bytes equals exact stream length and when BoundedIO reads a larger slice at EOF" do
      exact = Crystal::Cbor::Fido.encode("ctap2-exact")
      io = IO::Memory.new(exact)
      Crystal::Cbor::Fido::Decoder.decode(io, max_bytes: exact.size.to_u64, eof_check: true).should eq("ctap2-exact")

      bounded = Crystal::Cbor::Fido::BoundedIO.new(IO::Memory.new(Bytes[1, 2, 3, 4]), 4_u64)
      buf = Bytes.new(8)
      bounded.read(buf).should eq(4)
      buf[0, 4].should eq(Bytes[1, 2, 3, 4])
      bounded.read(buf).should eq(0)
    end
  end

  # Verifies [FUNC-007] / [TECH-005] / [TECH-007]
  describe "TASK-204: RFC 8949 Appendix A Diagnostic Test Vectors" do
    it "verifies RFC 8949 Appendix A unsigned and negative integer vectors" do
      int_vectors = {
                        0_i64 => "00",
                        1_i64 => "01",
                       10_i64 => "0a",
                       23_i64 => "17",
                       24_i64 => "1818",
                       25_i64 => "1819",
                      100_i64 => "1864",
                     1000_i64 => "1903e8",
                1_000_000_i64 => "1a000f4240",
        1_000_000_000_000_i64 => "1b000000e8d4a51000",
                       -1_i64 => "20",
                      -10_i64 => "29",
                     -100_i64 => "3863",
                    -1000_i64 => "3903e7",
        Int64::MIN            => "3b7fffffffffffffff",
      }

      int_vectors.each do |val, expected_hex|
        encoded = Crystal::Cbor::Fido.encode(val)
        encoded.hexstring.should eq(expected_hex)
        Crystal::Cbor::Fido.decode(encoded).should eq(val)
      end

      max_u64 = 18_446_744_073_709_551_615_u64
      encoded_u64 = Crystal::Cbor::Fido.encode(max_u64)
      encoded_u64.hexstring.should eq("1bffffffffffffffff")
      Crystal::Cbor::Fido.decode(encoded_u64).should eq(max_u64)
    end

    it "verifies RFC 8949 Appendix A canonical floating-point narrowing vectors" do
      float_vectors = [
        {0.0, "f90000"},
        {-0.0, "f98000"},
        {1.0, "f93c00"},
        {1.5, "f93e00"},
        {65_504.0, "f97bff"},
        {100_000.0, "fa47c35000"},
        {3.402_823_466_385_288_6e+38, "fa7f7fffff"},
        {1.1, "fb3ff199999999999a"},
        {1.0e+300, "fb7e37e43c8800759c"},
        {5.960_464_477_539_062_5e-8, "f90001"},
        {0.000_061_035_156_25, "f90400"},
        {-4.0, "f9c400"},
        {-4.1, "fbc010666666666666"},
        {Float64::INFINITY, "f97c00"},
        {-Float64::INFINITY, "f9fc00"},
      ]

      float_vectors.each do |val, expected_hex|
        encoded = Crystal::Cbor::Fido.encode(val)
        encoded.hexstring.should eq(expected_hex)
        decoded = Crystal::Cbor::Fido.decode(encoded).as(Float64)
        decoded.should eq(val)
        if val == 0.0
          decoded.unsafe_as(UInt64).should eq(val.unsafe_as(UInt64))
        end
      end

      nan_bytes = Crystal::Cbor::Fido.encode(Float64::NAN)
      nan_bytes.hexstring.should eq("f97e00")
      Crystal::Cbor::Fido.decode(nan_bytes).as(Float64).nan?.should be_true
    end

    it "verifies RFC 8949 Appendix A simple, string, byte-string, array, and map vectors" do
      Crystal::Cbor::Fido.encode(false).hexstring.should eq("f4")
      Crystal::Cbor::Fido.encode(true).hexstring.should eq("f5")
      Crystal::Cbor::Fido.encode(nil).hexstring.should eq("f6")

      Crystal::Cbor::Fido.encode(Bytes.empty).hexstring.should eq("40")
      Crystal::Cbor::Fido.encode(Bytes[1, 2, 3, 4]).hexstring.should eq("4401020304")

      string_vectors = {
        "" => "60", "a" => "6161", "IETF" => "6449455446",
        "\"\\" => "62225c", "\u00fc" => "62c3bc", "\u6c34" => "63e6b0b4",
      }
      string_vectors.each do |str, hex|
        encoded = Crystal::Cbor::Fido.encode(str)
        encoded.hexstring.should eq(hex)
        Crystal::Cbor::Fido.decode(encoded).should eq(str)
      end

      empty_arr = Array(Crystal::Cbor::Fido::Value).new
      Crystal::Cbor::Fido.encode(empty_arr).hexstring.should eq("80")

      nested_arr = [
        1_i64,
        [2_i64, 3_i64] of Crystal::Cbor::Fido::Value,
        [4_i64, 5_i64] of Crystal::Cbor::Fido::Value,
      ] of Crystal::Cbor::Fido::Value
      encoded_nested = Crystal::Cbor::Fido.encode(nested_arr)
      encoded_nested.hexstring.should eq("8301820203820405")
      Crystal::Cbor::Fido.decode(encoded_nested).should eq(nested_arr)

      arr_25 = Array(Crystal::Cbor::Fido::Value).new(25) { |idx| (idx + 1).to_i64.as(Crystal::Cbor::Fido::Value) }
      encoded_25 = Crystal::Cbor::Fido.encode(arr_25)
      encoded_25.hexstring.should eq("98190102030405060708090a0b0c0d0e0f101112131415161718181819")
      Crystal::Cbor::Fido.decode(encoded_25).should eq(arr_25)

      map_vec = {
        "a" => 1_i64,
        "b" => [2_i64, 3_i64] of Crystal::Cbor::Fido::Value,
      } of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value
      encoded_map = Crystal::Cbor::Fido.encode(map_vec)
      encoded_map.hexstring.should eq("a26161016162820203")
      Crystal::Cbor::Fido.decode(encoded_map).should eq(map_vec)
    end

    it "rejects RFC 8949 Appendix A indefinite-length and non-canonical encodings" do
      indefinite_vectors = [
        "5f42010243030405ff",         # Indefinite byte string
        "7f657374726561646d696e67ff", # Indefinite text string
        "9fff",                       # Indefinite empty array
        "9f018202039f0405ffff",       # Indefinite nested array
        "bf61610161629f0203ffff",     # Indefinite map
      ]
      indefinite_vectors.each do |hex|
        expect_raises(Crystal::Cbor::Fido::CborError) do
          Crystal::Cbor::Fido.decode(hex.hexbytes)
        end
      end
    end
  end
end
