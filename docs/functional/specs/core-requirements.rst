=================
Core Requirements
=================

Functional Requirements
-----------------------

* **[FUNC-001] Canonical Integer and Primitive Encoding**:
  The shard must encode ``Int64``, ``UInt64``, ``Bool``, ``Nil``, ``String``, ``Bytes``, and definite-length ``Array`` containers using the shortest-length RFC 8949 Section 4.2 argument headers (inline ``0..23``, 1-byte ``24``, 2-byte ``25``, 4-byte ``26``, or 8-byte ``27``). Indefinite-length headers (additional information ``31``) are forbidden. Fulfilled by ``[TECH-001]`` in :doc:`../../technical/specs/architecture-overview` and delivered by ``TASK-103`` in :doc:`../../project/roadmaps/phase-1-mvp`.

* **[FUNC-002] Deterministic CTAP2 Map Key Sorting**:
  The encoder must serialize all map keys to canonical CBOR bytes and sort entries by shortest encoded byte length first and unsigned byte-wise lexicographical order second per CTAP2 Section 6. If two distinct Crystal map keys serialize to identical canonical bytes, the encoder must raise ``Crystal::Cbor::Fido::CanonicalError``. Fulfilled by ``[TECH-001]`` and ``[TECH-005]`` in :doc:`../../technical/specs/architecture-overview` and :doc:`../../technical/specs/threat-model`, and delivered by ``TASK-103`` in :doc:`../../project/roadmaps/phase-1-mvp`.

* **[FUNC-003] Lossless IEEE 754 Floating-Point Narrowing**:
  The encoder must narrow ``Float64`` values through the lossless progression ``Float64`` -> ``Float32`` -> ``Float16`` whenever the numeric value is exactly representable in a narrower IEEE 754 format, including exact ``Float16`` subnormal arithmetic (:math:`1 \times 2^{-24}`) and round-to-nearest-even rounding. All ``NaN`` payloads must normalize to canonical quiet ``Float16`` ``0x7e00`` (wire bytes ``0xf97e00``), and positive zero must encode as ``+0.0`` ``0x0000`` (wire bytes ``0xf90000``), while preserving ``-0.0`` as ``0x8000`` (wire bytes ``0xf98000``). Fulfilled by ``[TECH-002]`` and ``[TECH-005]`` in :doc:`../../technical/specs/architecture-overview` and :doc:`../../technical/specs/threat-model`, and delivered by ``TASK-102`` in :doc:`../../project/roadmaps/phase-1-mvp`.

* **[FUNC-004] Strict Canonical Decoding and Validation**:
  The decoder must reject non-minimal integer headers, non-narrowed ``Float32`` or ``Float64`` values, non-canonical ``Float16`` ``NaN`` bit patterns, duplicate or unsorted map keys, invalid UTF-8 text strings, forbidden simple values, truncated inputs, nesting depths exceeding ``MAX_DEPTH``, allocation lengths exceeding ``MAX_LEN``, and top-level trailing bytes by raising ``Crystal::Cbor::Fido::CborError`` (``CBORError``) or its ``CanonicalError`` and ``DepthError`` subclasses. Fulfilled by ``[TECH-003]`` and ``[TECH-005]`` in :doc:`../../technical/specs/architecture-overview` and :doc:`../../technical/specs/threat-model`, and delivered by ``TASK-104`` in :doc:`../../project/roadmaps/phase-1-mvp`.

* **[FUNC-005] Zero External Runtime Dependencies**:
  The shard must execute exclusively against the Crystal standard library with zero external runtime dependencies, enforcing strict static typing, zero ``.not_nil!`` assertions, and zero-warning static analysis and release gates. Fulfilled by ``[TECH-001]``, ``[TECH-004]``, ``[TECH-005]``, and the release playbook in :doc:`../../technical/specs/architecture-overview`, :doc:`../../technical/specs/coding-standards`, :doc:`../../technical/specs/threat-model`, and :doc:`../../technical/specs/release-procedure`, and delivered by ``TASK-101`` and ``TASK-105`` in :doc:`../../project/roadmaps/phase-1-mvp`.

* **[FUNC-006] Compile-Time CBOR::Serializable Macro Annotation**:
  In Phase 2 ``v0.2.2``, the shard will provide a compile-time ``Crystal::Cbor::Fido::Serializable`` (``CBOR::Serializable``) module, ``@[CBOR::Field(key: ..., ignore: ...)]`` annotation, and ``@[CBOR::Serializable::Options(strict: Bool = true)]`` configuration for zero-boilerplate struct and class canonical serialization and deserialization. Duplicate CBOR map keys must unconditionally raise ``CanonicalError`` regardless of ``strict`` mode, while ``@[CBOR::Serializable::Options(strict: Bool = true)]`` controls solely whether unknown/unmapped CBOR keys raise ``CborError`` (``strict: true``, default) or are skipped after canonical key-order validation (``strict: false``). Fulfilled by ``[TECH-006]`` in :doc:`../../technical/specs/architecture-overview` and delivered by ``TASK-201`` and ``TASK-202`` in :doc:`../../project/roadmaps/phase-2-enhancement`.

* **[FUNC-007] Bounded Streaming IO Codec and RFC 8949 Appendix A Vector Verification**:
  In Phase 2 ``v0.2.2``, the shard will expose bounded streaming ``IO`` entrypoints ``Encoder.encode(value, io : IO, max_depth : Int32 = MAX_DEPTH) : Nil`` and ``Decoder.decode(io : IO, max_depth : Int32 = MAX_DEPTH, max_bytes : UInt64 = 1_048_576_u64, eof_check : Bool = true) : Value`` where ``MAX_DEPTH = 16`` aligns with Phase 1 container depth limits, ``max_bytes = 1_048_576_u64`` enforces a 1 MiB default streaming budget bounded by the absolute ceiling ``MAX_LEN = 10_000_000_u64``, and ``eof_check: true`` rejects trailing bytes at EOF for single-frame payloads while ``eof_check: false`` supports multi-frame stream decoding, verified against the complete RFC 8949 Appendix A diagnostic vector corpus. Fulfilled by ``[TECH-005]`` and ``[TECH-007]`` in :doc:`../../technical/specs/architecture-overview` and :doc:`../../technical/specs/threat-model`, and delivered by ``TASK-203`` and ``TASK-204`` in :doc:`../../project/roadmaps/phase-2-enhancement`.

Requirement Traceability Matrix
-------------------------------

.. list-table::
   :widths: 16 34 22 16 12
   :header-rows: 1

   * - Requirement ID
     - Capability Summary
     - Technical Specs
     - Roadmap Tasks
     - Release
   * - ``[FUNC-001]``
     - Canonical integer and primitive encoding
     - ``[TECH-001]``
     - ``TASK-103``
     - ``v0.2.1``
   * - ``[FUNC-002]``
     - Deterministic CTAP2 map key sorting
     - ``[TECH-001]``, ``[TECH-005]``
     - ``TASK-103``
     - ``v0.2.1``
   * - ``[FUNC-003]``
     - Lossless IEEE 754 floating-point narrowing
     - ``[TECH-002]``, ``[TECH-005]``
     - ``TASK-102``
     - ``v0.2.1``
   * - ``[FUNC-004]``
     - Strict canonical decoding and validation
     - ``[TECH-003]``, ``[TECH-005]``
     - ``TASK-104``
     - ``v0.2.1``
   * - ``[FUNC-005]``
     - Zero external runtime dependencies
     - ``[TECH-001]``, ``[TECH-004]``, ``[TECH-005]``
     - ``TASK-101``, ``TASK-105``
     - ``v0.2.1``
   * - ``[FUNC-006]``
     - Compile-time ``CBOR::Serializable`` macro annotation
     - ``[TECH-006]``
     - ``TASK-201``, ``TASK-202``
     - ``v0.2.2``
   * - ``[FUNC-007]``
     - Bounded streaming ``IO`` codec & RFC 8949 vectors
     - ``[TECH-005]``, ``[TECH-007]``
     - ``TASK-203``, ``TASK-204``
     - ``v0.2.2``
