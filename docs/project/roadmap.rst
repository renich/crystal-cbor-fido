========================================
Crystal CBOR-FIDO Project Master Roadmap
========================================

.. toctree::
   :maxdepth: 2
   :caption: Roadmap Phases

   roadmaps/phase-1-mvp
   roadmaps/phase-2-release

Executive Summary
=================
This document outlines the phased engineering milestones and release lifecycle for ``crystal-cbor-fido``, providing strict compliance with FIDO2 / CTAP2 Canonical CBOR encoding and decoding standards.

Phase Breakdown
===============
* **Phase 1 (MVP Baseline)**: Core Canonical CBOR parser, SipHash-2-4 deterministic map key ordering, IEEE 754 Float16 bit manipulation, and initial test vectors.
* **Phase 2 (Crucible Refactoring & Release Stabilization)**: Adversarial audit remediation, Float16 complexity reduction, zero lint warnings, and v0.1.1 production release.
