Crystal CBOR FIDO Architecture
==============================

Overview
--------

This document outlines the core architectural components and decisions for the FIDO Canonical CBOR implementation. The design focuses on memory safety, determinism, correctness, and adherence to strict FIDO specifications.

Core Components
---------------

SipHash
~~~~~~~

The SipHash module provides a robust SipHash-2-4 implementation designed to prevent hash flooding attacks. It enforces strict constraints, such as requiring exactly a 16-byte key.

SipHashSet
~~~~~~~~~~

A set data structure built on top of SipHash.

* Uses constant-time equality to avoid timing attacks, rejecting partial matches or differing lengths safely.
* Dynamically scales by rehashing when the capacity exceeds 75%.
* Rejects duplicate insertions efficiently.

Float16
~~~~~~~

IEEE 754 Half-Precision floating-point implementation. FIDO CBOR heavily utilizes Float16 to minimize payload sizes.

* Handles normal and subnormal numbers, along with special values like NaN, Infinity, and zero.
* Provides functionality to check if a Float64 value is exactly representable as Float16 without precision loss.

Encoder
~~~~~~~

The Encoder module is responsible for encoding native structures according to strict FIDO Canonical CBOR rules.

* Automatically selects minimal length representation for integers.
* Prefers Float16 representation if the original float is exactly representable.
* Enforces strict map key sorting: keys are sorted by length first (shortest to longest), then by byte-wise lexicographical comparison.

Decoder
~~~~~~~

The Decoder is strictly designed to parse CBOR types back to native Crystal types.

* Raises explicit exceptions on invalid or truncated formats.
* Resolves types securely based on byte width.
