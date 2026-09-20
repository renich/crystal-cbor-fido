# crystal-cbor-fido

[![CI](https://gitlab.com/renich/crystal-cbor-fido/badges/master/pipeline.svg)](https://gitlab.com/renich/crystal-cbor-fido/-/pipelines)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

A high-performance, strictly compliant, and hardened **Canonical CBOR** (RFC 8949) encoder and decoder implementation for [Crystal](https://crystal-lang.org/), designed specifically for FIDO2 and CTAP2 protocol compliance.

## Features

- **Strict Canonical CBOR Compliance**: Enforces minimal integer representations, deterministic map key ordering (shorter length first, then byte-wise lexicographical), and rejects duplicate keys.
- **IEEE 754 Half-Precision (`Float16`) Support**: Exact subnormal precision decoding ($1 \times 2^{-24} \approx 5.96 \times 10^{-8}$) and round-to-nearest-even bit manipulation.
- **Protocol Hardening**: Rejects undefined simple values (23), reserved tokens, and invalid UTF-8 byte sequences.
- **Defensive Resource Bounding**: Enforces a maximum nesting depth of 16 and caps maximum array/string/map sizes to prevent stack and heap exhaustion attacks.
- **Full 64-bit Integer Support**: Fully supports `Int64` and `UInt64` scalar ranges without precision loss.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crystal-cbor-fido:
    github: renich/crystal-cbor-fido
    version: ~> 0.1.2
```

Then run:

```bash
shards install
```

## Usage

```crystal
require "crystal-cbor-fido"

# Encoding a canonical CBOR payload
data = {} of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value
data["user_id"] = 100_i64
data["challenge"] = "rand123"

# Convenience encoder
bytes = Crystal::Cbor::Fido.encode(data)
puts "Encoded CBOR (Hex): #{bytes.hexstring}"

# Convenience decoder
decoded_data = Crystal::Cbor::Fido.decode(bytes)
puts "Decoded Data: #{decoded_data.inspect}"
```

## Development & Verification

Build targets and test suites are managed via GNU Make:

```bash
make all      # Runs linting (Ameba & Flaw) and the full test suite
make test     # Executes crystal spec
make lint     # Executes Ameba static analysis and Flaw scanner
make docs     # Generates API documentation into docs/technical/api
```

## Documentation

- **API Documentation**: Generated HTML docs located at [`docs/technical/api/`](docs/technical/api/index.html).
- **Technical Specification**: [`docs/technical/spec.rst`](docs/technical/spec.rst)
- **White Paper**: [`docs/whitepaper.rst`](docs/whitepaper.rst)
- **Project Roadmap**: [`docs/project/roadmap.rst`](docs/project/roadmap.rst)
- **Changelog**: [`CHANGELOG.rst`](CHANGELOG.rst)
- **Code of Honor**: [`docs/technical/CODE_OF_HONOR.rst`](docs/technical/CODE_OF_HONOR.rst)

## License

This project is licensed under the **GNU Affero General Public License v3.0 or later** ([AGPL-3.0-or-later](LICENSE)).
