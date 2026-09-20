Crystal CBOR FIDO White Paper
=============================

Abstract
--------
The crystal-cbor-fido project is a purpose-built, native Crystal implementation of Canonical Concise Binary Object Representation (CBOR), meticulously designed for FIDO2 and CTAP2 protocol compliance. This document details the architectural choices, cryptographic measures, and safety guarantees that ensure the implementation remains deterministic, secure, and performant under adversarial conditions.

Purpose
-------
FIDO2 and CTAP2 standards require precise Canonical CBOR representations to ensure cryptographic signatures match across disparate systems. Standard CBOR libraries often lack the strict determinism and specific security hardening required for these protocols. The primary purpose of crystal-cbor-fido is to provide a production-grade, hardened encoder and decoder that guarantees memory safety, prevents canonicalization violations, and mitigates common web authentication attack vectors such as hash flooding, integer overflow, and timing side-channels.

Architecture
------------
The architecture is structured around strict separation of encoding and decoding responsibilities, bolstered by highly specialized data structures.

Encoder
~~~~~~~
The Encoder is responsible for emitting canonically correct CBOR. It automatically selects the minimal length representation for integers and enforces strict map key sorting. Keys are sorted by length first, followed by a byte-wise lexicographical comparison. The Encoder also validates that outgoing maps are canonical before emission, explicitly checking for canonical ordering and duplicate keys.

Decoder
~~~~~~~
The Decoder rigorously parses CBOR payloads back into native Crystal types. It operates on a strict fail-fast principle, explicitly raising exceptions upon encountering invalid bytes, truncated formats, or non-canonical structures. It resolves types securely based on precise byte widths.

Float16 Specialization
~~~~~~~~~~~~~~~~~~~~~~
FIDO CBOR heavily utilizes IEEE 754 Half-Precision (Float16) to minimize payload sizes. The architecture implements exact Float16 bit manipulation, accurately handling normal numbers, subnormal numbers, NaN, Infinity, and zero. The library deterministically identifies if a 64-bit float can be losslessly represented as Float16, bypassing standard library Float32 approximations that cause truncation bugs.

Cryptography
------------
Cryptographic hardening is embedded directly into the library's foundational data structures, prioritizing resilience against targeted exploits.

SipHash Integration
~~~~~~~~~~~~~~~~~~~
The implementation integrates a native SipHash-2-4 keyed hash function. This cryptographic hash is utilized exclusively for internal data structures to prevent hash flooding (collision) attacks. It enforces strict constraints, requiring precisely a 16-byte key generated from a secure random source upon instantiation.

Constant-Time Operations
~~~~~~~~~~~~~~~~~~~~~~~~
To mitigate timing side-channel attacks, the library enforces bitwise, branchless constant-time equality checks for sensitive comparisons. Operations iterating over secret data, such as Map keys during duplicate detection or authentication checks, calculate accumulated byte differences via bitwise OR without conditional exits.

Safety Guarantees
-----------------
The implementation guarantees predictable, safe execution through several explicitly defined boundaries.

Integer Type Safety
~~~~~~~~~~~~~~~~~~~
CBOR negative integer decoding is susceptible to underflow. To prevent this, the library utilizes 128-bit signed arithmetic for all intermediate calculations when processing negative integers. It explicitly bounds values between standard 64-bit limits, securely falling back to BigInt representations if capacity is exceeded.

Algorithmic Complexity
~~~~~~~~~~~~~~~~~~~~~~
Map decoding replaces naive linear scans with optimized structures. By leveraging SipHash-based sets and binary searches over sorted arrays, duplicate key detection operates at an average complexity of O(n log n), actively preventing CPU exhaustion attacks on massive payloads.

Proof of Functionality
----------------------
The implementation has undergone rigorous adversarial review and unit testing, successfully passing all cryptographic and safety evaluations across all test cases. Critical functionality verified includes:

* **Depth Limitation:** Adherence to a maximum nesting depth of 16 to prevent stack overflow attacks.
* **Allocation Bounds:** Enforced payload size limitations strictly capped at 10MB to prevent memory exhaustion.
* **Canonical Map Compliance:** Confirmed exact FIDO standard map key sorting (ordered by length, then by lexicographical byte value) alongside strict duplicate key rejection.
* **Precision Integrity:** Validation of precise IEEE 754 Float16 boundaries, confirming the absence of precision truncation.
