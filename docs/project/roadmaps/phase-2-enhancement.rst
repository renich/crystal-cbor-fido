====================
Phase 2: Enhancement
====================

Timeline & Objectives
---------------------
Extend ``crystal-cbor-fido`` with declarative ``CBOR::Serializable`` macro annotations for FIDO2/COSE structs, CTAP2 test vector corpus integration, and continuous micro-benchmarking.

Milestones & Deliverables
-------------------------

* **Milestone 2.1: Declarative Struct Serialization**:

  - [ ] Compile-time ``Crystal::Cbor::Fido::Serializable`` module for zero-boilerplate mapping of COSE keys and CTAP2 command parameters.
  - [ ] Support for integer-keyed COSE maps (e.g. ``kty: 1``, ``alg: 3``, ``crv: -1``, ``x: -2``, ``y: -3``) with compile-time canonical key ordering.

* **Milestone 2.2: Benchmarking & Differential Fuzzing**:

  - [ ] Micro-benchmarking suite comparing throughput and allocation counts across CTAP2 attestation payloads.
  - [ ] Differential fuzzing harness against RFC 8949 Appendix A and FIDO2 conformance test vectors.
