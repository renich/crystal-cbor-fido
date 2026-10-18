========================================
Crystal CBOR-FIDO Project Master Roadmap
========================================

Executive Summary
=================

This document outlines the phased engineering milestones and release lifecycle for ``crystal-cbor-fido``, providing strict compliance with FIDO2 and CTAP2 Canonical CBOR encoding and decoding standards.

Roadmap Phases
--------------

* `Phase 1: Canonical CBOR Encoder and Decoder Core MVP <roadmaps/phase-1-mvp.rst>`__
* `Phase 2: Crucible Protocol Refactoring and Release Stabilization <roadmaps/phase-2-release.rst>`__

Phase Breakdown
===============

* **Phase 1 — MVP Baseline**: Core Canonical CBOR parser, deterministic map key ordering, IEEE 754 Float16 bit manipulation, and initial test vectors.
* **Phase 2 — Crucible Refactoring and Release Stabilization**: Adversarial audit remediation, Float16 complexity reduction, canonical integer width enforcement, zero lint warnings, and ``v0.1.2`` release.
* **Phase 3 — Echelon and Crucible v0.2.0 Hardening**: Strict IEEE 754 canonical float decoding, top-level trailing byte rejection, duplicate serialized map key rejection on encode, cumulative allocation budgeting, and lean CI/CD pipeline.
