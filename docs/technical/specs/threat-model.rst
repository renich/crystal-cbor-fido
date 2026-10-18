============
Threat Model
============

Requirement Mapping
-------------------
Fulfills ``[FUNC-002]``, ``[FUNC-003]``, ``[FUNC-004]``, ``[FUNC-005]``.

Security Posture
----------------

* **Signature Malleability Prevention**: Rejects non-minimal integer encodings, non-minimal float widths, non-canonical ``Float16`` ``NaN`` bit patterns, unsorted or duplicate map keys, forbidden ``undefined`` (simple value ``23``), unassigned simple values, indefinite-length items (additional info ``31``), and trailing top-level bytes so every valid logical structure has a unique canonical wire encoding.
* **Memory & Arithmetic Safety**: Pure Crystal implementation with bounds-checked slice reads, explicit ``IO::EOFError`` conversion to ``CborError`` on truncated streams, UTF-8 validity verification on text strings, and 128-bit intermediate signed arithmetic (``Int128``) preventing negative integer underflow.
* **Supply Chain Integrity**: Zero external runtime shard dependencies eliminate third-party transitive vulnerabilities.

Resource and Framing Bounds
---------------------------

* **Top-Level Framing**: ``Crystal::Cbor::Fido.decode`` requires the entire input slice to be consumed by a single top-level CBOR data item, raising ``CanonicalError`` if trailing bytes remain.
* **Nesting Depth Limit**: ``Encoder`` and ``Decoder`` enforce ``MAX_DEPTH = 16`` across arrays, maps, and serialized map keys to prevent stack exhaustion attacks.
* **Cumulative Allocation Cap**: ``Decoder`` enforces ``MAX_LEN = 10_000_000_u64`` both per item and cumulatively across ``@total_allocated`` within a decode session, capping initial container pre-allocation at ``1024`` entries to prevent single-header heap exhaustion.

Adversarial Verification Matrix
-------------------------------

#. **Integer Boundaries**: Verified minimal encoding and decoding across ``0``, ``23``, ``24``, ``255``, ``256``, ``65535``, ``65536``, ``UInt32::MAX``, ``Int64::MAX``, ``UInt64::MAX``, ``Int64::MIN``, and underflow below ``Int64::MIN``.
#. **Float16 Precision**: Verified subnormal boundaries (:math:`2^{-24}`, :math:`2^{-15}`), round-to-nearest-even rounding, signed zeros, infinities, and canonical ``0x7e00`` ``NaN``.
#. **Canonical Strictness**: Confirmed rejection of non-minimal integers, non-minimal floats, non-canonical ``NaN`` bit patterns, unsorted map keys, duplicate map keys on both encode and decode, and trailing top-level bytes.
#. **Resource Exhaustion**: Confirmed rejection of container nesting exceeding ``MAX_DEPTH = 16`` and oversized single or cumulative allocations exceeding ``MAX_LEN = 10_000_000_u64``.
