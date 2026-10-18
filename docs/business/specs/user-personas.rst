=============
User Personas
=============

Primary Stakeholders
--------------------

* **FIDO2 and WebAuthn Protocol Engineer**: Requires deterministic CBOR serialization, compile-time ``CBOR::Serializable`` struct mapping, and strict canonical validation for COSE keys, attestation statements, and CTAP2 authenticator messages.
* **Security and Cryptography Auditor**: Requires transparent bounds checking, :math:`O(1)` streaming map key order verification, 128-bit underflow-safe negative integer decoding, bounded streaming ``IO`` limits, and zero C-binding memory hazards.
* **Autonomous AI Coding Agent**: Requires unambiguous module contracts, bidirectional requirement traceability (``[FUNC-001]``..``[FUNC-007]`` <-> ``[TECH-001]``..``[TECH-007]``), strongly-typed ``Crystal::Cbor::Fido::Value`` unions, structured exception hierarchies, and zero-suppression static analysis gates.
