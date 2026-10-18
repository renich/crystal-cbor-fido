Crystal CBOR FIDO Architecture
==============================

Overview
--------

This document outlines the core architectural components and design decisions for the FIDO Canonical CBOR implementation. The design focuses on memory safety, determinism, correctness, and adherence to strict RFC 8949 Section 4.2 and FIDO2/CTAP2 Section 6 specifications.

Core Components
---------------

Types and Error Hierarchy
~~~~~~~~~~~~~~~~~~~~~~~~~

The ``types.cr`` module defines the recursive ``Value`` union type and a structured exception hierarchy:

* ``CborError``: Base exception raised for malformed CBOR structures, invalid UTF-8 strings, truncated streams, or allocation limit violations.
* ``CanonicalError``: Subclass of ``CborError`` raised when a payload violates Canonical CBOR rules, including non-minimal integer or floating-point widths, non-canonical ``Float16`` NaN bit patterns, unsorted or duplicate map keys, forbidden simple values, or trailing top-level bytes.
* ``DepthError``: Subclass of ``CborError`` raised when container nesting exceeds ``MAX_DEPTH`` (16).

Float16
~~~~~~~

IEEE 754 half-precision (``binary16``) floating-point implementation in ``float16.cr``. FIDO CBOR utilizes ``Float16`` to minimize payload sizes.

* Handles normal and subnormal numbers with IEEE 754 round-to-nearest-even using guard and sticky bit inspection, along with special values such as canonical quiet NaN (``0x7e00``), Infinity, ``+0.0``, and ``-0.0``.
* Provides ``Float16.exactly_representable?`` to determine whether a ``Float64`` value can be losslessly represented in 16 bits.

Encoder
~~~~~~~

The ``Encoder`` class in ``encoder.cr`` serializes native Crystal ``Value`` structures according to FIDO Canonical CBOR rules.

* Automatically selects minimal width representations for unsigned and negative integers via ``write_type_and_arg``.
* Selects the narrowest lossless IEEE 754 representation (``Float16``, ``Float32``, or ``Float64``) for floating-point numbers.
* Enforces canonical map key ordering: keys are pre-encoded with nesting depth propagation, sorted by byte length first and then byte-wise lexicographical order, verified against duplicate canonical keys, and written directly to the output stream.

Decoder
~~~~~~~

The ``Decoder`` class in ``decoder.cr`` parses CBOR byte streams back to native Crystal ``Value`` instances with strict validation.

* Enforces minimal integer and floating-point width encodings, canonical ``Float16`` NaN bit patterns (``0x7e00``), and strict ascending canonical key order in maps with :math:`O(1)` state overhead.
* Enforces a maximum nesting depth of 16 and tracks both per-item and cumulative allocations against a 10 MB budget (``MAX_LEN``).
* Converts truncated stream reads (``IO::EOFError``) into deterministic ``CborError`` exceptions.
