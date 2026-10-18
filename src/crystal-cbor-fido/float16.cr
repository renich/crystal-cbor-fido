module Crystal::Cbor::Fido
  # IEEE 754 half-precision (`binary16`) floating-point conversion and canonical representability utilities.
  module Float16
    # Bitmask isolating the 1-bit sign field (`bit 15`) of an IEEE 754 `binary16` word.
    SIGN_MASK = 0x8000_u16

    # Bitmask isolating the 5-bit biased exponent field (`bits 14..10`) of an IEEE 754 `binary16` word.
    EXP_MASK = 0x7C00_u16

    # Bitmask isolating the 10-bit significand mantissa field (`bits 9..0`) of an IEEE 754 `binary16` word.
    MAN_MASK = 0x03FF_u16

    # Converts a `Float64` to its 16-bit IEEE 754 half-precision bit pattern using round-to-nearest-even.
    def self.from_float64(value : Float64) : UInt16
      if special = encode_special(value)
        return special
      end

      bits = value.unsafe_as(UInt64)
      sign = ((bits >> 63) & 1).to_u16
      exponent = ((bits >> 52) & 0x7FF).to_i32 - 1023
      mantissa = bits & 0xFFFFFFFFFFFFF_u64

      case
      when exponent > 15
        (sign << 15) | EXP_MASK
      when exponent < -24
        sign << 15
      when exponent >= -14
        encode_normalized(sign, exponent, mantissa)
      else
        encode_subnormal(sign, exponent, mantissa)
      end
    end

    # Converts a 16-bit IEEE 754 half-precision bit pattern into a `Float64`.
    def self.to_float64(bits : UInt16) : Float64
      sign = (bits & SIGN_MASK) >> 15
      exponent = ((bits & EXP_MASK) >> 10).to_i32
      mantissa = (bits & MAN_MASK).to_u64

      case exponent
      when 0x1F
        mantissa == 0 ? (sign == 0 ? Float64::INFINITY : -Float64::INFINITY) : Float64::NAN
      when 0
        return sign == 0 ? 0.0 : -0.0 if mantissa == 0
        val = mantissa.to_f64 * (2.0 ** -24)
        sign == 0 ? val : -val
      else
        val = (1.0 + (mantissa.to_f64 / 1024.0)) * (2.0 ** (exponent - 15))
        sign == 0 ? val : -val
      end
    end

    # Returns `true` if *value* can be losslessly represented as an IEEE 754 half-precision float (`Float16`).
    def self.exactly_representable?(value : Float64) : Bool
      return true if value.nan? || value.infinite? || value == 0.0

      f16_bits = from_float64(value)
      back_to_f64 = to_float64(f16_bits)
      value == back_to_f64
    end

    private def self.encode_special(value : Float64) : UInt16?
      case
      when value.nan?
        0x7E00_u16
      when value.infinite?
        value > 0 ? EXP_MASK : (SIGN_MASK | EXP_MASK)
      when value == 0.0
        bits = value.unsafe_as(UInt64)
        sign = ((bits >> 63) & 1).to_u16
        sign << 15
      end
    end

    private def self.encode_normalized(sign : UInt16, exponent : Int32, mantissa : UInt64) : UInt16
      new_exp = exponent + 15
      new_man = ((mantissa >> 42) & MAN_MASK).to_u16
      round_bit = (mantissa >> 41) & 1
      sticky = (mantissa & 0x1FFFFFFFFFF_u64) != 0 ? 1 : 0

      if round_bit == 1 && (sticky == 1 || (new_man & 1) == 1)
        new_man += 1
        if new_man > MAN_MASK
          new_man = 0_u16
          new_exp += 1
          return (sign << 15) | EXP_MASK if new_exp >= 31
        end
      end

      (sign << 15) | (new_exp.to_u16 << 10) | new_man
    end

    private def self.encode_subnormal(sign : UInt16, exponent : Int32, mantissa : UInt64) : UInt16
      shift = -14 - exponent
      return sign << 15 if shift > 10

      full_man = (1_u64 << 52) | mantissa
      round_pos = 42 + shift - 1
      round_bit = (full_man >> round_pos) & 1
      sticky_mask = (1_u64 << round_pos) - 1
      sticky = (full_man & sticky_mask) != 0 ? 1 : 0

      new_man = (full_man >> (42 + shift)).to_u16
      if round_bit == 1 && (sticky == 1 || (new_man & 1) == 1)
        new_man += 1
      end

      (sign << 15) | (new_man & MAN_MASK)
    end
  end
end
