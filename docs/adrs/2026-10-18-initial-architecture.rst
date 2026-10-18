====================================================
ADR-001: Canonical CBOR Zero-Dependency Architecture
====================================================

:Status: Accepted
:Date: 2026-10-18
:Deciders: EVALinux Cryptography Architecture Team

Context
-------
FIDO2 and CTAP2 Relying Parties and authenticators require strict Canonical CBOR serialization and validation per RFC 8949 Section 4.2 and CTAP2 Section 6 (``[FUNC-001]`` through ``[FUNC-005]``). General-purpose CBOR implementations depend on external libraries or permit non-canonical encodings such as indefinite lengths, non-minimal numeric widths, and unsorted or duplicate map keys, creating cryptographic signature malleability and memory-exhaustion risks.

Decision
--------

#. **Zero Third-Party Runtime Dependencies**: The shard must implement all CBOR major types and IEEE 754 ``Float16`` conversions purely against the Crystal standard library (``[FUNC-005]``, ``[TECH-001]``, ``[TECH-004]``).
#. **Fail-Closed Canonical Enforcement**: The codec must reject non-minimal integers, non-minimal floats, non-canonical ``Float16`` ``NaN`` bit patterns (``bits != 0x7e00``), duplicate or unsorted map keys, forbidden simple values, and trailing top-level bytes with ``Crystal::Cbor::Fido::CanonicalError`` (``[FUNC-003]``, ``[FUNC-004]``, ``[TECH-002]``, ``[TECH-003]``, ``[TECH-005]``).
#. **Streaming Map Key Order Verification**: The decoder must validate map key sorting and uniqueness in :math:`O(1)` auxiliary memory during decoding by comparing each key's canonical bytes against the immediately preceding key, while the encoder pre-sorts stack-allocated ``Encoder::MapEntry`` records during encoding (``[FUNC-002]``, ``[TECH-001]``, ``[TECH-003]``).
#. **Hard Resource Bounds**: Both ``Encoder`` and ``Decoder`` must enforce ``MAX_DEPTH = 16`` across containers and map keys, and ``Decoder`` must cap per-item and cumulative session allocations at ``MAX_LEN = 10_000_000_u64`` bytes (``[FUNC-004]``, ``[TECH-005]``).

Consequences
------------

* **Positive**: Deterministic byte-for-byte wire representations, immunity to signature malleability, predictable memory bounds, and zero supply-chain attack surface.
* **Negative**: Non-canonical CBOR streams emitted by non-compliant encoders are deterministically rejected rather than silently normalized on decode.
