=================================================================
ADR-002: Compile-Time CBOR::Serializable and Bounded Streaming IO
=================================================================

:Status: Accepted
:Date: 2026-10-18
:Deciders: EVALinux Cryptography Architecture Team

Context
-------
Phase 1 (``v0.2.1``) established a hardened, zero-dependency Canonical CBOR codec operating over the recursive ``Crystal::Cbor::Fido::Value`` union and in-memory ``Bytes`` slices (``[FUNC-001]`` through ``[FUNC-005]``). Downstream FIDO2 Relying Party and CTAP2 authenticator libraries require two additional capabilities for ``v0.2.2``:

#. Declarative, compile-time mapping between strongly-typed Crystal structs/classes (such as COSE keys with negative integer labels ``-1``, ``-2``, ``-3`` and WebAuthn attestation structures) and Canonical CBOR without manual ``Hash(Value, Value)`` construction boilerplate (``[FUNC-006]``).
#. Direct streaming serialization and deserialization over ``IO`` endpoints with caller-configurable nesting depth and byte budget limits aligned with Phase 1 constants, validated against the complete RFC 8949 Appendix A diagnostic vector corpus (``[FUNC-007]``).

Decision
--------

#. **Compile-Time AST Macro Serialization** (``[FUNC-006]``/``[TECH-006]``):
   Phase 2 ``v0.2.2`` will introduce ``Crystal::Cbor::Fido::Serializable`` (aliased as ``CBOR::Serializable``), the ``@[CBOR::Field(key: ..., ignore: ...)]`` annotation, and ``@[CBOR::Serializable::Options(strict: Bool = true)]``. Rather than relying on runtime reflection or intermediate ``Hash(Value, Value)`` allocations, the ``included`` macro will inspect instance variables at compile time, pre-compute canonical key ordering per CTAP2 Section 6, and synthesize type-safe ``#to_cbor`` and ``.from_cbor`` methods. Duplicate CBOR map keys will unconditionally raise ``CanonicalError`` regardless of mode, while ``@[CBOR::Serializable::Options(strict: Bool = true)]`` will control solely whether unknown/unmapped CBOR keys raise ``CborError`` (``strict: true``, default) or are skipped after canonical key-order validation (``strict: false``).

#. **Bounded Streaming IO Codec** (``[FUNC-007]``/``[TECH-007]``):
   Phase 2 ``v0.2.2`` will expose ``Encoder.encode(value, io : IO, max_depth : Int32 = MAX_DEPTH) : Nil`` and ``Decoder.decode(io : IO, max_depth : Int32 = MAX_DEPTH, max_bytes : UInt64 = 1_048_576_u64, eof_check : Bool = true) : Value`` where ``MAX_DEPTH = 16`` aligns with Phase 1 container depth limits and ``max_bytes = 1_048_576_u64`` enforces a 1 MiB default streaming budget bounded by the absolute ceiling ``MAX_LEN = 10_000_000_u64``. Single-frame callers use ``eof_check: true`` (default) to reject trailing bytes at EOF with ``CanonicalError``, while multi-frame stream callers pass ``eof_check: false``.

#. **RFC 8949 Appendix A Vector Verification** (``[FUNC-007]``/``[TECH-005]``):
   All RFC 8949 Appendix A diagnostic vectors compatible with the CTAP2 canonical profile will be encoded and decoded in automated specs to verify bit-exact round-trip determinism.

Consequences
------------

* **Positive**: Zero intermediate hash-map allocations for typed FIDO2/COSE structures, unconditional immunity to duplicate-key injection, compile-time type safety, deterministic streaming memory ceilings over untrusted sockets/pipes, and exhaustive RFC 8949 Appendix A conformance.
* **Negative**: Macro-generated initializers increase compile-time AST expansion work for large domain models, which is mitigated by keeping ``CBOR::Serializable`` opt-in per struct or class.
