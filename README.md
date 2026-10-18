# crystal-cbor-fido

[![CI](https://gitlab.com/renich/crystal-cbor-fido/badges/master/pipeline.svg)](https://gitlab.com/renich/crystal-cbor-fido/-/pipelines)
[![Version](https://img.shields.io/badge/version-v0.2.1-blue.svg)](https://gitlab.com/renich/crystal-cbor-fido/-/releases)
[![Crystal](https://img.shields.io/badge/crystal-%3E%3D%201.21.0-black.svg)](https://crystal-lang.org/)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

A high-performance, zero-dependency, strictly compliant, and hardened **Canonical CBOR** (RFC 8949 §4.2 / CTAP2 §6) encoder and decoder implementation for [Crystal](https://crystal-lang.org/), designed specifically for FIDO2, WebAuthn, and COSE protocol compliance.

---

## Features

- **Strict Canonical CBOR Compliance**: Enforces minimal integer and floating-point representations, deterministic map key ordering (shorter byte length first, then byte-wise lexicographical), duplicate serialized key rejection on both encode and decode, and top-level trailing byte rejection.
- **IEEE 754 Half-Precision (`Float16`) Support**: Exact subnormal precision decoding ($1 \times 2^{-24} \approx 5.96 \times 10^{-8}$), round-to-nearest-even bit manipulation with guard and sticky bit inspection, and canonical `0x7e00` NaN enforcement.
- **Protocol Hardening**: Rejects undefined simple values (`23`), unassigned simple values, reserved length tokens (`28..30`), indefinite-length items (`31`), and invalid UTF-8 byte sequences.
- **Defensive Resource Bounding**: Enforces a maximum nesting depth of 16 (propagated into serialized map keys) and a cumulative allocation budget (`MAX_LEN = 10_000_000` bytes) across nested containers to prevent stack and heap exhaustion attacks.
- **Full 64-bit Integer Support**: Supports full `Int64` and `UInt64` scalar ranges without precision loss, using 128-bit intermediate signed arithmetic (`Int128`) during negative integer decoding.

---

## Installation

Add `crystal-cbor-fido` to your application's `shard.yml`:

```yaml
dependencies:
  crystal-cbor-fido:
    gitlab: renich/crystal-cbor-fido
    version: ~> 0.2.1
```

Then run:

```bash
shards install
```

---

## Usage

```crystal
require "crystal-cbor-fido"

# Encoding a canonical CBOR payload
data = Hash(Crystal::Cbor::Fido::Value, Crystal::Cbor::Fido::Value).new
data["user_id"] = 100_i64
data["challenge"] = "rand123"

# Convenience encoder
bytes = Crystal::Cbor::Fido.encode(data)
puts "Encoded CBOR (Hex): #{bytes.hexstring}"

# Convenience decoder (rejects non-canonical encodings and trailing bytes)
decoded_data = Crystal::Cbor::Fido.decode(bytes)
puts "Decoded Data: #{decoded_data.inspect}"
```

---

## Build System Targets

Build targets, static analyzers, documentation builders, and test suites are managed via `GNUmakefile`:

| Target | Description |
| :--- | :--- |
| `make all` | Runs `lint` (`crystal tool format --check`, Ameba, Flaw) and `test` (`crystal spec`) |
| `make check` | Alias for `test` target per GNU standards |
| `make test` | Executes the Crystal spec suite (`crystal spec`) |
| `make lint` | Runs `crystal tool format --check`, `bin/ameba --all`, and `bin/flaw scan .` |
| `make format` | Formats Crystal source and spec files (`crystal tool format src spec`) |
| `make doc-check` | Lints all reStructuredText files using `crstlint -r .` and `rstcheck` |
| `make docs` | Generates Crystal API docs (`docs/technical/api`) and Sphinx `dirhtml` (`docs/build/dirhtml`) |
| `make clean` | Removes generated documentation, linter binaries, and build artifacts |

---

## Documentation

Full architectural blueprints, functional specifications, and operational playbooks are maintained under [`docs/`](docs/index.rst):

| Guide | Scope & Highlights | Entry Point |
| :--- | :--- | :--- |
| **Business Context & Strategy** | FIDO2 ecosystem problem statement, ROI metrics, and personas. | [Business Specs](docs/business/spec.rst) |
| **Functional Specifications** | Requirements `[FUNC-001]`–`[FUNC-006]` and canonical contracts. | [Functional Specs](docs/functional/spec.rst) |
| **Technical Architecture** | Internal design, `Float16` math, coding standards, and threat model. | [Technical Specs](docs/technical/spec.rst) |
| **Release Playbook** | SemVer, Keep a Changelog, and GPG-signed GitLab release steps. | [Release Procedure](docs/technical/specs/release-procedure.rst) |
| **Architecture Decisions** | Immutable logs of architectural decisions and trade-offs. | [ADR Index](docs/adrs/index.rst) |
| **Project Roadmap** | Phased milestone tracking, deliverables, and audit history. | [Project Roadmap](docs/project/roadmap.rst) |
| **User Documentation** | Installation, usage examples, and exception handling guide. | [Getting Started](docs/user/guides/getting-started.rst) |
| **Crystal API Reference** | Compiler-generated HTML API reference (`make docs`). | `docs/technical/api/index.html` |

---

## Contributing & Code of Honor

All contributions must adhere to the [Universal Code of Honor](CODE_OF_HONOR.rst) and [Contributing Guidelines](CONTRIBUTING.rst).

---

## License

- **Software**: GNU Affero General Public License v3.0 or later ([LICENSE](LICENSE)).
- **Documentation**: GNU Free Documentation License v1.3 or later ([LICENSE-DOCS](LICENSE-DOCS)).
