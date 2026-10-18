====================================================
[TECH-005] Threat Model and Cryptographic Mitigation
====================================================

Requirement Mapping
-------------------
Fulfills ``[FUNC-002]``, ``[FUNC-003]``, ``[FUNC-004]``, ``[FUNC-005]``, ``[FUNC-007]``.

Threat Surface and Mitigations
------------------------------

* **Signature Malleability Prevention**:
  FIDO2 attestation signatures and WebAuthn assertion signatures sign raw CBOR structures. If two distinct byte sequences decode to the same logical map or scalar, an attacker can mutate signed packets or bypass replay caches. ``crystal-cbor-fido`` eliminates malleability by rejecting non-minimal integer encodings, non-minimal float widths, non-canonical ``Float16`` ``NaN`` bit patterns (``bits != 0x7e00``), unsorted or duplicate map keys, forbidden ``undefined`` (simple value ``23``), unassigned simple values, and indefinite-length items (additional info ``31``).

* **Parser Confusion and Duplicate Key Injection**:
  Inconsistent duplicate-key handling between a Relying Party validator and downstream policy engines enables authorization bypasses. Both ``Encoder`` and ``Decoder`` (including ``CBOR::Serializable`` initializers regardless of ``strict`` mode) enforce strict CTAP2 map key ordering and deterministically raise ``CanonicalError`` upon encountering duplicate canonical key bytes.

* **Resource Exhaustion and Bomb Mitigation**:
  Crafted CBOR headers declaring multi-gigabyte container lengths or deeply nested arrays/maps can trigger stack overflow or out-of-memory termination. ``Encoder`` and ``Decoder`` enforce hard container nesting limits (``max_depth : Int32 = MAX_DEPTH`` where ``MAX_DEPTH = 16``), cap initial container pre-allocation at ``1024`` elements, and enforce cumulative byte allocation budgets (``MAX_LEN = 10_000_000_u64`` absolute ceiling and ``max_bytes : UInt64 = 1_048_576_u64`` 1 MiB default streaming budget).

* **Trailing-Byte Injection Prevention**:
  Top-level decoding via ``Crystal::Cbor::Fido.decode`` and single-frame streaming decoding with ``eof_check: true`` require the input to be consumed by a single top-level CBOR data item, raising ``CanonicalError`` if unconsumed trailing bytes remain.

* **Arithmetic and Memory Safety**:
  Pure Crystal implementation with bounds-checked slice reads, explicit ``IO::EOFError`` conversion to ``CborError`` on truncated streams, UTF-8 validity verification on text strings, and 128-bit intermediate signed arithmetic (``Int128``) preventing negative integer underflow below ``Int64::MIN``.

Adversarial Verification Matrix
-------------------------------

#. **Integer Boundaries**: Verified minimal encoding and decoding across ``0``, ``23``, ``24``, ``255``, ``256``, ``65535``, ``65536``, ``UInt32::MAX``, ``Int64::MAX``, ``UInt64::MAX``, ``Int64::MIN``, and underflow below ``Int64::MIN``.
#. **Float16 Precision**: Verified subnormal boundaries (:math:`2^{-24}`, :math:`2^{-15}`), round-to-nearest-even rounding, signed zeros (``+0.0`` -> ``0x0000``, ``-0.0`` -> ``0x8000``), infinities, and canonical ``0x7e00`` ``NaN``.
#. **Canonical Strictness**: Confirmed rejection of non-minimal integers, non-minimal floats, non-canonical ``NaN`` bit patterns, unsorted map keys, duplicate map keys on both encode and decode, and trailing top-level bytes.
#. **Resource Exhaustion**: Confirmed rejection of container nesting exceeding ``MAX_DEPTH`` and oversized single or cumulative allocations exceeding ``MAX_LEN``.
