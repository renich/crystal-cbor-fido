=================
Core Requirements
=================

Functional Requirements
-----------------------

* **[FUNC-001] Canonical CBOR Major Type Serialization & Deserialization**:
  The shard must encode and decode unsigned integers (Major Type 0), negative integers (Major Type 1), byte strings (Major Type 2), UTF-8 text strings (Major Type 3), definite-length arrays (Major Type 4), definite-length maps (Major Type 5), and canonical simple/floating-point values (Major Type 7) using the minimal possible CBOR argument width per RFC 8949 Section 4.2 and CTAP2 Section 6.

* **[FUNC-002] Deterministic Map Key Ordering & Duplicate Rejection**:
  The encoder must sort map keys by canonically encoded byte length first and unsigned byte-wise lexicographical order second, raising ``Crystal::Cbor::Fido::CanonicalError`` if two distinct Crystal keys serialize to identical canonical bytes. The decoder must verify strictly ascending canonical key order in :math:`O(1)` auxiliary memory and reject unsorted or duplicate keys with ``Crystal::Cbor::Fido::CanonicalError``.

* **[FUNC-003] IEEE 754 Half-Precision & Minimal Float Canonicalization**:
  The encoder must serialize ``Float64`` values into the narrowest lossless IEEE 754 representation (``Float16``, ``Float32``, or ``Float64``), implementing exact subnormal arithmetic (:math:`1 \times 2^{-24}`) and IEEE 754 round-to-nearest-even with guard and sticky bit inspection, and encoding ``NaN`` canonically as ``0xf97e00``. The decoder must reject non-canonical ``Float16`` ``NaN`` bit patterns and any ``Float32`` or ``Float64`` value losslessly representable in a narrower format.

* **[FUNC-004] Framing Strictness & Resource Bounds Enforcement**:
  Top-level decoding via ``Crystal::Cbor::Fido.decode`` must reject trailing unconsumed bytes with ``Crystal::Cbor::Fido::CanonicalError``. Both ``Encoder`` and ``Decoder`` must enforce ``MAX_DEPTH = 16`` (including nested map keys) by raising ``Crystal::Cbor::Fido::DepthError``, and ``Decoder`` must enforce both per-item and cumulative allocation caps (``MAX_LEN = 10_000_000_u64``) by raising ``Crystal::Cbor::Fido::CborError``.

* **[FUNC-005] Typed Exception Hierarchy & Zero Dependency Core**:
  The shard must execute with zero external runtime dependencies and provide a structured exception hierarchy rooted at ``Crystal::Cbor::Fido::CborError``, with ``Crystal::Cbor::Fido::CanonicalError`` and ``Crystal::Cbor::Fido::DepthError`` subclasses for fine-grained protocol error handling.

* **[FUNC-006] Automated Documentation & Release**:
  The project must build both Sphinx architectural documentation and compiler-generated Crystal API documentation, enforcing zero-warning quality gates across all code and documentation files.
