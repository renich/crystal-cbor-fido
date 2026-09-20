=========
Changelog
=========

All notable changes to this project will be documented in this file.

The format is based on `Keep a Changelog <https://keepachangelog.com/en/1.1.0/>`_,
and this project adheres to `Semantic Versioning <https://semver.org/spec/v2.0.0.html>`_.

[Unreleased]
============

[0.1.2] - 2026-09-19
====================

.. rubric:: Security

- Enforced RFC 8949 Section 4.2 / CTAP2 Canonical CBOR integer encoding (rejected non-minimal lengths on decode).
- Enforced strict canonical map key ordering (shorter length first, then bytewise lexicographical) and O(1) duplicate key rejection on decode.
- Added strict UTF-8 byte validation for decoded text strings.
- Rejected unassigned simple values and forbidden undefined (23) values per CTAP2 specifications.

.. rubric:: Fixed

- Corrected Float16 subnormal math bug (corrected shifting power from 2^-22 to exact 2^-24).
- Implemented true IEEE 754 round-to-nearest-even with guard and sticky bit logic in Float16 encoder.

.. rubric:: Added

- Added full 64-bit unsigned scalar integer support (``UInt64``).
- Purged dead SipHash code and unused dependencies.

.. rubric:: Refactored

- Modularized 584-line monolith into submodules under 185 lines (``types.cr``, ``float16.cr``, ``encoder.cr``, and ``decoder.cr``).

[0.1.1] - 2026-08-13
====================

.. rubric:: Refactored

- Decomposed ``Float16.from_float64`` into modular helper methods (``encode_special``, ``encode_normalized``, ``encode_subnormal``), removing lint cyclomatic complexity suppression.

[0.1.0] - 2026-06-05
====================

.. rubric:: Added

- Initial orchestrated release of the architecture.
- Full TDD specifications with >80% code coverage.
- Code of Honor integration.
- FHS 3 compliant GNUmakefile.
- GitLab CI/CD Alpine pipeline.
