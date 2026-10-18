# crystal-cbor-fido

[![CI](https://gitlab.com/renich/crystal-cbor-fido/badges/master/pipeline.svg)](https://gitlab.com/renich/crystal-cbor-fido/-/pipelines)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

A high-performance, strictly compliant, and hardened **Canonical CBOR** (RFC 8949 §4.2 / CTAP2 §6) encoder and decoder implementation for [Crystal](https://crystal-lang.org/), designed specifically for FIDO2 and WebAuthn protocol compliance.

## Features

- **Strict Canonical CBOR Compliance**: Enforces minimal integer and floating-point representations, deterministic map key ordering (shorter byte length first, then byte-wise lexicographical), duplicate serialized key rejection on both encode and decode, and top-level trailing byte rejection.
- **IEEE 754 Half-Precision (`Float16`) Support**: Exact subnormal precision decoding ($1 \times 2^{-24} \approx 5.96 \times 10^{-8}$), round-to-nearest-even bit manipulation, and canonical `0x7e00` NaN enforcement.
- **Protocol Hardening**: Rejects undefined simple values (`23`), unassigned simple values, reserved length tokens (`28..30`), indefinite-length items (`31`), and invalid UTF-8 byte sequences.
- **Defensive Resource Bounding**: Enforces a maximum nesting depth of 16 (propagated into serialized map keys) and a cumulative allocation budget (`MAX_LEN = 1_048_576` bytes) across nested containers to prevent stack and heap exhaustion attacks.
- **Full 64-bit Integer Support**: Supports full `Int64` and `UInt64` scalar ranges without precision loss.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crystal-cbor-fido:
    gitlab: renich/crystal-cbor-fido
    version: ~> 0.2.0
```

Then run:

```bash
shards install
```

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

## Development & Verification

Build targets and test suites are managed via GNU Make:

```bash
make all      # Runs linting (format check, Ameba --all, Flaw) and the full test suite
make check    # Executes crystal spec
make lint     # Executes crystal tool format --check, Ameba --all, and Flaw scanner
make docs     # Generates API documentation into docs/technical/api
```

## Documentation

- **API Documentation**: Generated HTML docs located at [`docs/technical/api/`](docs/technical/api/index.html)
- **Technical Specification**: [`docs/technical/spec.rst`](docs/technical/spec.rst)
- **Architecture & Design**: [`docs/technical/architecture.rst`](docs/technical/architecture.rst)
- **White Paper**: [`docs/whitepaper.rst`](docs/whitepaper.rst)
- **Project Roadmap**: [`docs/project/roadmap.rst`](docs/project/roadmap.rst)
- **Changelog**: [`CHANGELOG.rst`](CHANGELOG.rst)
- **Code of Honor**: [`docs/technical/CODE_OF_HONOR.rst`](docs/technical/CODE_OF_HONOR.rst)

## License

This project is licensed under the **GNU Affero General Public License v3.0 or later** ([AGPL-3.0-or-later](LICENSE)).
