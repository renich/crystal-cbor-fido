<p align="center">
  <img src="assets/banner.svg" alt="crystal-cbor-fido Banner" width="100%" />
</p>

<p align="center">
  <strong>Memory-safe, zero-dependency Canonical CBOR (RFC 8949 §4.2 and CTAP2 §6) encoder and decoder for Crystal with IEEE 754 float narrowing and strict validation.</strong>
</p>

<p align="center">
  <a href="https://gitlab.com/renich/crystal-cbor-fido/-/releases"><img src="https://img.shields.io/badge/version-v0.2.1-blue.svg?style=flat-square" alt="Version 0.2.1" /></a>
  <a href="https://crystal-lang.org/"><img src="https://img.shields.io/badge/crystal-%3E%3D%201.21.0-black.svg?style=flat-square&logo=crystal&logoColor=white" alt="Crystal >= 1.21.0" /></a>
  <a href="https://gitlab.com/renich/crystal-cbor-fido/-/pipelines"><img src="https://img.shields.io/badge/pipeline-passing-brightgreen.svg?style=flat-square&logo=gitlab" alt="GitLab CI Passing" /></a>
  <a href="https://gitlab.com/renich/crystal-cbor-fido"><img src="https://img.shields.io/badge/specs-39%20passing-success.svg?style=flat-square&logo=crystal" alt="Specs Passing" /></a>
  <a href="https://github.com/crystal-ameba/ameba"><img src="https://img.shields.io/badge/ameba-0%20violations-brightgreen.svg?style=flat-square" alt="Ameba Clean" /></a>
  <a href="https://github.com/kdairatchi/flaw"><img src="https://img.shields.io/badge/flaw-0%20findings-brightgreen.svg?style=flat-square" alt="Flaw Clean" /></a>
</p>

<p align="center">
  <a href="https://renich.gitlab.io/crystal-cbor-fido/"><img src="https://img.shields.io/badge/docs-Sphinx%20Portal-orange.svg?style=flat-square&logo=sphinx&logoColor=white" alt="Sphinx Documentation" /></a>
  <a href="https://renich.gitlab.io/crystal-cbor-fido/technical/api/"><img src="https://img.shields.io/badge/api-Crystal%20Docs-8A2BE2.svg?style=flat-square&logo=crystal&logoColor=white" alt="Crystal API Documentation" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue.svg?style=flat-square" alt="License: GPL-3.0-or-later" /></a>
  <a href="https://liberapay.com/Renich/donate"><img src="https://img.shields.io/badge/liberapay-donate-yellow.svg?style=flat-square&logo=liberapay&logoColor=white" alt="Donate using Liberapay" /></a>
</p>

> **GitLab Project Metadata**:
> - **Description**: Memory-safe Canonical CBOR (RFC 8949 §4.2 and CTAP2 §6) encoder and decoder for Crystal with IEEE 754 float narrowing and strict validation.
> - **Topics and Tags**: `crystal`, `crystal-lang`, `cbor`, `fido2`, `ctap2`, `webauthn`, `rfc8949`, `serialization`, `security`, `gplv3`

---

## Overview

**crystal-cbor-fido** provides a deterministic, zero-dependency, and hardened **Canonical CBOR** (RFC 8949 §4.2 and FIDO2 CTAP2 §6) encoder and decoder for [Crystal](https://crystal-lang.org/), purpose-built for FIDO2, WebAuthn, and COSE protocol compliance.

### Key Highlights

1. **Strict Canonical CBOR Compliance**: Enforces minimal integer and floating-point widths, deterministic CTAP2 map key ordering (shorter byte length first, then unsigned byte-wise lexicographical order), duplicate serialized key rejection on both encode and decode, and top-level trailing-byte rejection.
2. **IEEE 754 Half-Precision (`Float16`) Narrowing**: Lossless `Float64 -> Float32 -> Float16` narrowing with exact subnormal precision ($1 \times 2^{-24} \approx 5.96 \times 10^{-8}$), round-to-nearest-even bit manipulation with guard and sticky bit inspection, canonical `0x7e00` `NaN`, and `+0.0` `0x0000` normalization.
3. **Defensive Resource Bounding & 128-Bit Integer Safety**: Enforces `MAX_DEPTH = 16` across containers and serialized map keys, caps cumulative session allocations at `MAX_LEN = 10_000_000` bytes, and uses `Int128` signed intermediate arithmetic for negative integer decoding.
4. **Zero Runtime Dependencies & Multi-Tier Documentation**: Executes purely on the Crystal Standard Library and includes complete Business, Functional (`[FUNC-001]`–`[FUNC-007]`), Technical (`[TECH-001]`–`[TECH-007]`), ADR, D2 diagram, and compiler-generated API documentation.

---

## Installation

Add `crystal-cbor-fido` to your application's `shard.yml`:

```yaml
dependencies:
  crystal-cbor-fido:
    gitlab: renich/crystal-cbor-fido
    version: ~> 0.2.1
```

Then install the shard:

```bash
shards install
```

---

## Usage

```crystal
require "crystal-cbor-fido"

# Build a canonical CBOR map using the recursive Value union
data = Hash(Crystal::Cbor::Fido::Value, Crystal::Cbor::Fido::Value).new
data["user_id"] = 100_i64
data["challenge"] = "rand123"

# Encode into deterministic Canonical CBOR wire bytes
bytes = Crystal::Cbor::Fido.encode(data)
puts "Encoded CBOR (Hex): #{bytes.hexstring}"

# Decode and validate canonical CBOR bytes (rejects non-canonical inputs and trailing bytes)
decoded_data = Crystal::Cbor::Fido.decode(bytes)
puts "Decoded Data: #{decoded_data.inspect}"

# Rescue typed domain exceptions
begin
  Crystal::Cbor::Fido.decode(Bytes[0x18, 0x05])
rescue ex : Crystal::Cbor::Fido::CanonicalError
  STDERR.puts "Canonical violation: #{ex.message}"
end
```

---

## Build System Targets

The repository includes a standard `GNUmakefile`:

| Target | Description |
| :--- | :--- |
| `make all` | Runs `lint` (`crystal tool format --check`, Ameba, Flaw) and `test` (`crystal spec`) |
| `make check` | Alias for `test` target per GNU standards |
| `make test` | Executes the Crystal spec suite (`crystal spec`) |
| `make lint` | Runs `crystal tool format --check`, `bin/ameba --all`, and `bin/flaw scan .` |
| `make format` | Formats Crystal source and spec files (`crystal tool format src spec`) |
| `make doc-check` | Lints all reStructuredText files using `crstlint` and `rstcheck` |
| `make docs` | Generates Crystal API docs (`docs/technical/api`) and Sphinx `dirhtml` (`docs/build/dirhtml`) |
| `make deps` | Installs Shards dependencies and builds `bin/ameba` and `bin/flaw` |
| `make clean` | Removes generated documentation, linter binaries, and build artifacts |

---

## Documentation

Full architectural blueprints, functional specifications, D2 diagrams, and operational playbooks are maintained under [`docs/`](docs/index.rst):

| Guide | Scope & Highlights | Entry Point |
| :--- | :--- | :--- |
| **Business Context & Strategy** | FIDO2 ecosystem problem statement, ROI metrics, and personas. | [Business Specs](docs/business/spec.rst) |
| **Functional Specifications** | Requirements `[FUNC-001]`–`[FUNC-007]` and canonical contracts. | [Functional Specs](docs/functional/spec.rst) |
| **Technical Architecture** | Specs `[TECH-001]`–`[TECH-007]`, D2 architecture diagram, and threat model. | [Technical Specs](docs/technical/spec.rst) |
| **Release Playbook** | SemVer, Keep a Changelog, and GPG-signed GitLab release steps. | [Release Procedure](docs/technical/specs/release-procedure.rst) |
| **Architecture Decisions (ADRs)** | Immutable logs of architectural decisions (`ADR-001`, `ADR-002`). | [ADR Index](docs/adrs/index.rst) |
| **Project Roadmap** | Phased milestone tracking (`TASK-101`–`TASK-204`) and D2 dependency graphs. | [Project Roadmap](docs/project/roadmap.rst) |
| **User Documentation** | Installation, usage examples, and exception handling guide. | [Getting Started](docs/user/guides/getting-started.rst) |
| **Crystal API Reference** | Complete interactive type hierarchy and method signatures. | [API Reference](https://renich.gitlab.io/crystal-cbor-fido/technical/api/) |

---

## Contributing & Code of Honor

All contributions must adhere to the [Universal Code of Honor](CODE_OF_HONOR.rst) and [Contributing Guidelines](CONTRIBUTING.rst).

---

## License

- **Software**: GNU General Public License v3.0 or later ([LICENSE](LICENSE)).
- **Documentation**: GNU Free Documentation License v1.3 or later ([LICENSE-DOCS](LICENSE-DOCS)).

Copyleft &copy; 2026 Rénich Bon Ćirić &lt;renich@evalinux.com&gt;.

---

## Support & Donations

If you find this shard useful and wish to support its ongoing development, please consider donating:

<p align="center">
  <a href="https://liberapay.com/Renich/donate">
    <img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg" />
  </a>
</p>
