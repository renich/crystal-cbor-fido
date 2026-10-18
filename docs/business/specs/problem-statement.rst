=================
Problem Statement
=================

Context
-------
FIDO2 and CTAP2 authentication protocols require deterministic Canonical CBOR (RFC 8949 Section 4.2 and CTAP2 Section 6) representations so that cryptographic signatures over attestation objects, authenticator data, and COSE keys verify identically across heterogeneous platforms. General-purpose CBOR libraries frequently permit non-canonical constructs such as indefinite-length containers, non-minimal integer or floating-point widths, unsorted or duplicate map keys, unassigned simple values, and unbounded nesting or allocation lengths, exposing Relying Parties and authenticators to signature malleability and denial-of-service vectors.

Solution
--------
``crystal-cbor-fido`` provides a zero-dependency, pure Crystal Canonical CBOR encoder and decoder purpose-built for FIDO2 and WebAuthn workloads. It enforces minimal integer and IEEE 754 floating-point widths (including exact ``Float16`` subnormal and round-to-nearest-even arithmetic), deterministic map key ordering with duplicate key rejection on both encode and decode paths, top-level trailing byte rejection, and strict nesting depth and cumulative allocation bounds.
