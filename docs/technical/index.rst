Crystal CBOR FIDO Technical Documentation
=========================================

This document summarizes the production implementation and security invariants of the ``crystal-cbor-fido`` library.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   architecture
   spec

Canonical CBOR Guarantees
-------------------------

The implementation enforces strict compliance with RFC 8949 Section 4.2 and FIDO2/CTAP2 Section 6 across both encoding and decoding paths.

Deterministic Map Ordering and Duplicate Rejection
--------------------------------------------------

In Canonical CBOR, map keys must be sorted by their canonically encoded byte length first, followed by lexicographical byte order. Because incoming keys must appear in strictly ascending order, duplicate and out-of-order keys are detected in :math:`O(1)` memory during decoding by comparing each key with its immediate predecessor.

.. code-block:: crystal

   module Crystal::Cbor::Fido
     def self.compare_canonical_bytes(a : Bytes, b : Bytes) : Int32
       cmp = a.size <=> b.size
       cmp != 0 ? cmp : (a <=> b)
     end
   end

Float16 IEEE 754 Correctness
----------------------------

Floating-point values are always encoded using the narrowest IEEE 754 precision (``Float16``, ``Float32``, or ``Float64``) that preserves the exact numeric value, and non-minimal float encodings are rejected on decode.

.. code-block:: crystal

   module Crystal::Cbor::Fido::Float16
     def self.from_float64(value : Float64) : UInt16
       # Extracts sign, exponent, and mantissa
       # Handles normals (exponent -14 to 15) and subnormals (exponent -24 to -15)
       # Applies IEEE 754 round-to-nearest-even using guard and sticky bits
     end
   end

Implementation Highlights
-------------------------

* Zero-allocation-amplification :math:`O(1)` streaming map key order and duplicate verification on decode
* Exact ``Float16`` conversion with IEEE 754 subnormal and round-to-nearest-even semantics
* 128-bit intermediate signed arithmetic (``Int128``) preventing negative integer underflow
* Per-item and cumulative allocation budget enforcement (``MAX_LEN = 10_000_000``)
* Maximum container nesting depth enforcement (``MAX_DEPTH = 16``) including map keys

Verification Suite
------------------

The test suite verifies all canonical and adversarial invariants:

* Unit and boundary tests across all public methods and numeric widths
* Rejection of non-minimal integers, non-minimal floats, non-canonical ``Float16`` NaN bit patterns, and trailing top-level bytes
* Rejection of unsorted and duplicate map keys on both encode and decode paths
* Exhaustive formatting and static analysis checks via ``crystal tool format``, ``ameba``, and ``flaw``
