=====================
Architecture Overview
=====================

Requirement Mapping
-------------------
Fulfills ``[FUNC-001]``, ``[FUNC-002]``, ``[FUNC-003]``, ``[FUNC-004]``, ``[FUNC-005]``.

Library Layout & Namespaces
---------------------------
The library source is organized under the ``Crystal::Cbor::Fido`` namespace:

* **``src/crystal-cbor-fido.cr``**: Top-level module entrypoint providing ``.encode``, ``.decode`` (with trailing-byte rejection), ``.compare_canonical_bytes``, and ``.fits_in_float32_exactly?``.
* **``src/crystal-cbor-fido/types.cr``**: Recursive ``Value`` union alias and domain exception hierarchy (``CborError``, ``CanonicalError``, ``DepthError``).
* **``src/crystal-cbor-fido/float16.cr``**: IEEE 754 half-precision (``binary16``) bit manipulation, subnormal scaling (:math:`2^{-24}`), round-to-nearest-even rounding, and lossless representability checks.
* **``src/crystal-cbor-fido/encoder.cr``**: Deterministic Canonical CBOR serializer with ``MAX_DEPTH = 16`` enforcement and pre-serialized ``MapEntry`` key sorting.
* **``src/crystal-cbor-fido/decoder.cr``**: Strict Canonical CBOR deserializer with minimal-width verification, :math:`O(1)` streaming map key order checks, ``MAX_DEPTH = 16``, and cumulative ``MAX_LEN = 10_000_000_u64`` allocation accounting.

Canonical Byte Ordering and Duplicate Detection
-----------------------------------------------

CTAP2 Canonical Map Ordering
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CTAP2 Section 6 requires map keys to be ordered by their canonical CBOR byte representation:

#. Shorter encoded byte length sorts before longer encoded byte length.
#. Keys with identical encoded byte lengths sort in unsigned byte-wise lexicographical order.

.. code-block:: crystal

   module Crystal::Cbor::Fido
     def self.compare_canonical_bytes(a : Bytes, b : Bytes) : Int32
       cmp = a.size <=> b.size
       cmp != 0 ? cmp : (a <=> b)
     end
   end

Streaming Duplicate and Order Verification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Because valid Canonical CBOR maps must arrive in strictly ascending canonical key order, ``Decoder`` verifies both key sorting and uniqueness in :math:`O(1)` auxiliary memory by comparing each decoded key's canonical bytes against the immediately preceding key. On the encode path, ``Encoder`` pre-encodes keys into stack-allocated ``MapEntry`` records (propagating current ``@depth``), sorts them, and rejects adjacent duplicate ``key_bytes`` prior to writing.

.. code-block:: crystal

   private def verify_key_order(prev : Bytes?, current : Bytes) : Nil
     return unless prev
     cmp = Crystal::Cbor::Fido.compare_canonical_bytes(prev, current)
     return if cmp < 0
     raise CanonicalError.new("Duplicate key in canonical CBOR map") if cmp == 0
     raise CanonicalError.new("Keys in canonical CBOR map are not in sorted order")
   end

Integer Type Safety and Minimal Encoding
----------------------------------------

128-Bit Signed Intermediate Arithmetic
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CBOR major type 1 encodes negative integers as :math:`-1 - n`, where :math:`n` is an unsigned 64-bit integer argument. To prevent 64-bit signed integer underflow when :math:`n \ge 2^{63}`, ``Decoder#decode_negative`` uses 128-bit signed arithmetic (``Int128``) before range-checking against ``Int64::MIN``.

.. code-block:: crystal

   private def decode_negative(additional : UInt8) : Int64
     val = read_additional(additional)
     decoded = -1_i128 - val.to_i128
     if decoded < Int64::MIN
       raise CborError.new("Integer underflow")
     end
     decoded.to_i64
   end

Minimal Width Enforcement
~~~~~~~~~~~~~~~~~~~~~~~~~
Both integer values and container or string length arguments must use the smallest possible CBOR argument width:

* Values ``0..23`` must be encoded directly in the 5-bit additional information field.
* 1-byte arguments (additional info ``24``) must be ``>= 24``.
* 2-byte arguments (additional info ``25``) must be ``> 0xff``.
* 4-byte arguments (additional info ``26``) must be ``> 0xffff``.
* 8-byte arguments (additional info ``27``) must be ``> 0xffffffff``.

Float16, Float32, and Float64 Canonicalization
----------------------------------------------

IEEE 754 Narrowest Representation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Floating-point values are serialized into the narrowest IEEE 754 binary format (``Float16``, ``Float32``, or ``Float64``) that preserves the exact numeric value without precision loss. ``NaN`` is always canonically encoded as the quiet ``Float16`` bit pattern ``0xf97e00``.

.. code-block:: crystal

   private def encode_float(f : Float64) : Nil
     case
     when Float16.exactly_representable?(f)
       f16 = Float16.from_float64(f)
       @io.write_byte(0xf9_u8)
       @io.write_bytes(f16, IO::ByteFormat::BigEndian)
     when Crystal::Cbor::Fido.fits_in_float32_exactly?(f)
       @io.write_byte(0xfa_u8)
       @io.write_bytes(f.to_f32.unsafe_as(UInt32), IO::ByteFormat::BigEndian)
     else
       @io.write_byte(0xfb_u8)
       @io.write_bytes(f.unsafe_as(UInt64), IO::ByteFormat::BigEndian)
     end
   end

Decoder Float Minimal-Width Verification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
When decoding floating-point values, ``Decoder`` rejects non-canonical ``NaN`` bit patterns and non-minimal widths:

* ``Float16`` (additional info ``25``): Rejects any ``NaN`` bit pattern other than ``0x7e00``.
* ``Float32`` (additional info ``26``): Rejects ``NaN`` and any value losslessly representable in ``Float16``.
* ``Float64`` (additional info ``27``): Rejects ``NaN`` and any value losslessly representable in ``Float16`` or ``Float32``.
