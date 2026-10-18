============
Phase 1: MVP
============

Timeline & Objectives
---------------------
Deliver the core native Crystal implementation of Canonical CBOR encoding and decoding per RFC 8949 Section 4.2 and FIDO2 CTAP2 Section 6 specification requirements.

Milestones & Deliverables
-------------------------

* **Milestone 1.1: Core Canonical CBOR Runtime** — Fulfills ``[FUNC-001]``, ``[FUNC-002]``, ``[FUNC-003]``, ``[FUNC-005]``:

  - [x] Minimal-width integer, byte string, UTF-8 text string, array, and map serialization and deserialization (``Crystal::Cbor::Fido::Encoder``, ``Crystal::Cbor::Fido::Decoder``).
  - [x] Deterministic map key sorting (length-first, then byte-wise lexicographical) and :math:`O(1)` duplicate/order verification.
  - [x] IEEE 754 ``Float16`` half-precision bit manipulation with exact subnormal scaling (:math:`2^{-24}`) and round-to-nearest-even rounding.
  - [x] Domain exception hierarchy (``CborError``, ``CanonicalError``, ``DepthError``).

* **Milestone 1.2: Hardening, Build System & Quality Automation** — Fulfills ``[FUNC-004]``, ``[FUNC-006]``:

  - [x] Strict canonical float decoding, top-level trailing byte rejection, and duplicate map key rejection on encode.
  - [x] Nesting depth propagation (``MAX_DEPTH = 16``) into map keys and cumulative allocation budget tracking (``MAX_LEN = 10_000_000_u64``).
  - [x] Standard ``GNUmakefile`` with ``all``, ``check``, ``test``, ``lint``, ``doc-check``, and ``docs`` targets.
  - [x] Zero-suppression Ameba and Flaw SAST configurations and complete Sphinx + Crystal API documentation portal.
