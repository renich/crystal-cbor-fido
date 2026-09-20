module Crystal::Cbor::Fido
  module Float16
    SIGN_MASK = 0x8000_u16
    EXP_MASK  = 0x7C00_u16
    MAN_MASK  = 0x03FF_u16

    def self.from_float64(value : Float64) : UInt16
      if special = encode_special(value)
        return special
      end

      bits = value.unsafe_as(UInt64)
      sign = ((bits >> 63) & 1).to_u16
      exponent = ((bits >> 52) & 0x7FF).to_i32 - 1023
      mantissa = bits & 0xFFFFFFFFFFFFF_u64

      if exponent > 15
        (sign << 15 | 0x7C00).to_u16
      elsif exponent < -24
        (sign << 15).to_u16
      elsif exponent >= -14
        encode_normalized(sign, exponent, mantissa)
      else
        encode_subnormal(sign, exponent, mantissa)
      end
    end

    def self.to_float64(bits : UInt16) : Float64
      sign = (bits >> 15) & 1
      exponent = ((bits >> 10) & 0x1F).to_i32
      mantissa = (bits & 0x3FF).to_u64

      if exponent == 0x1F
        return mantissa == 0 ? (sign == 0 ? Float64::INFINITY : -Float64::INFINITY) : Float64::NAN
      end

      if exponent == 0
        return sign == 0 ? 0.0 : -0.0 if mantissa == 0
        val = mantissa.to_f64 * (2.0 ** -24)
        return sign == 0 ? val : -val
      end

      val = (1.0 + (mantissa.to_f64 / 1024.0)) * (2.0 ** (exponent - 15))
      sign == 0 ? val : -val
    end

    def self.exactly_representable?(value : Float64) : Bool
      return true if value.nan? || value.infinite? || value == 0.0

      f16_bits = from_float64(value)
      back_to_f64 = to_float64(f16_bits)
      value == back_to_f64
    end

    private def self.encode_special(value : Float64) : UInt16?
      if value.nan?
        0x7E00_u16
      elsif value.infinite?
        value > 0 ? 0x7C00_u16 : 0xFC00_u16
      elsif value == 0.0
        bits = value.unsafe_as(UInt64)
        sign = ((bits >> 63) & 1).to_u16
        (sign << 15).to_u16
      end
    end

    private def self.encode_normalized(sign : UInt16, exponent : Int32, mantissa : UInt64) : UInt16
      new_exp = exponent + 15
      new_man = ((mantissa >> 42) & 0x3FF).to_u16
      round_bit = (mantissa >> 41) & 1
      sticky = (mantissa & 0x1FFFFFFFFFF_u64) != 0 ? 1 : 0

      if round_bit == 1 && (sticky == 1 || (new_man & 1) == 1)
        new_man += 1
        if new_man > 0x3FF
          new_man = 0
          new_exp += 1
          return (sign << 15 | 0x7C00).to_u16 if new_exp >= 31
        end
      end

      (sign << 15 | (new_exp.to_u16 << 10) | new_man).to_u16
    end

    private def self.encode_subnormal(sign : UInt16, exponent : Int32, mantissa : UInt64) : UInt16
      shift = -14 - exponent
      return (sign << 15).to_u16 if shift > 10

      full_man = (1_u64 << 52) | mantissa
      round_pos = 42 + shift - 1
      round_bit = (full_man >> round_pos) & 1
      sticky_mask = (1_u64 << round_pos) - 1
      sticky = (full_man & sticky_mask) != 0 ? 1 : 0

      new_man = (full_man >> (42 + shift)).to_u16
      if round_bit == 1 && (sticky == 1 || (new_man & 1) == 1)
        new_man += 1
      end

      (sign << 15 | (new_man & 0x3FF)).to_u16
    end
  end
end
