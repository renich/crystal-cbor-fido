=================
ROI & Key Metrics
=================

Measurable Objectives
---------------------

#. **Strict Canonical Compliance**: The shard must guarantee 100% adherence to RFC 8949 Section 4.2 and FIDO2 CTAP2 Section 6 canonical encoding and decoding rules with zero tolerance for non-minimal or malleable inputs, verified against RFC 8949 Appendix A diagnostic test vectors.
#. **Zero External Runtime Dependencies**: The shard must rely exclusively on the Crystal standard library to eliminate transitive supply-chain risk in security-critical authentication paths.
#. **Deterministic Resource Safety**: The shard must enforce hard container nesting limits and bounded byte allocation caps across both in-memory slices and streaming ``IO`` cursors to prevent stack and heap exhaustion under adversarial input.
#. **Zero-Boilerplate Ergonomics & Quality Gates**: The shard will provide compile-time ``CBOR::Serializable`` struct and class serialization while maintaining 100% pass rates across unit and adversarial specs, ``crystal tool format``, ``ameba``, ``flaw``, ``crstlint``, and ``rstcheck`` with zero linter suppressions.
