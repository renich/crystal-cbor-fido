====================================================
ADR-001: Canonical CBOR Zero-Dependency Architecture
====================================================

:Status: Accepted
:Date: 2026-10-18
:Deciders: EVALinux Cryptography Architecture Team

Context
-------
FIDO2 and CTAP2 Relying Parties and authenticators require strict Canonical CBOR serialization and validation per RFC 8949 Section 4.2 and CTAP2 Section 6. General-purpose CBOR implementations often depend on external libraries or permit non-canonical encodings (indefinite lengths, non-minimal numeric widths, unsorted or duplicate map keys), creating cryptographic signature malleability and memory-exhaustion risks.

Decision
--------

#. **Zero Third-Party Runtime Dependencies**: Implement all CBOR major types and IEEE 754 ``Float16`` conversions purely against the Crystal standard library.
#. **Fail-Closed Canonical Enforcement**: Reject non-minimal integers, non-minimal floats, non-canonical ``Float16`` ``NaN`` bit patterns (``bits != 0x7e00``), duplicate or unsorted map keys, forbidden simple values, and trailing top-level bytes with ``Crystal::Cbor::Fido::CanonicalError``.
#. **Streaming Map Key Order Verification**: Validate map key sorting and uniqueness in :math:`O(1)` auxiliary memory during decoding by comparing each key's canonical bytes against the immediately preceding key, while pre-sorting stack-allocated ``Encoder::MapEntry`` records during encoding.
#. **Hard Resource Bounds**: Enforce ``MAX_DEPTH = 16`` across containers and map keys, and cap per-item and cumulative session allocations at ``MAX_LEN = 10_000_000_u64`` bytes.

Consequences
------------

* **Positive**: Deterministic byte-for-byte wire representations, immunity to signature malleability, predictable memory bounds, and zero supply-chain attack surface.
* **Negative**: Non-canonical CBOR streams emitted by non-compliant encoders are deterministically rejected rather than silently normalized on decode.
