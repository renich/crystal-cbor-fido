# crystal-cbor-fido

[![CI](https://gitlab.com/renich/crystal-cbor-fido/badges/master/pipeline.svg)](https://gitlab.com/renich/crystal-cbor-fido/-/pipelines)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

A high-performance, strictly compliant, and constant-time **Canonical CBOR** (RFC 8949) encoder and decoder implementation for [Crystal](https://crystal-lang.org/), tailored for FIDO2 and CTAP2 hardware security keys.

## Features

- **Strict Canonical CBOR Compliance**: Enforces deterministic key ordering (length first, then lexicographical order) and rejects duplicate map keys.
- **IEEE 754 Half-Precision (`Float16`) Support**: Full bitwise manipulation with exact conversion and representation verification.
- **Constant-Time Security**: Safe byte comparisons and bounds checking to mitigate timing side-channels.
- **Hash-DoS Protection**: Employs SipHash-2-4 for dictionary key hashing.
- **Zero Allocations & Overflow Safety**: Wrapping arithmetic (`&+`, `&-`) and explicit memory boundaries.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crystal-cbor-fido:
    github: renich/crystal-cbor-fido
    version: ~> 0.1.1
```

Then run:

```bash
shards install
```

## Usage

```crystal
require "crystal-cbor-fido"

# Encoding a canonical CBOR payload
io = IO::Memory.new
encoder = Crystal::Cbor::Fido::Encoder.new(io)

data = {} of Crystal::Cbor::Fido::Value => Crystal::Cbor::Fido::Value
data["user_id"] = 100_i64
data["challenge"] = "rand123"

encoder.encode(data)
bytes = io.to_slice
puts "Encoded CBOR (Hex): #{bytes.hexstring}"

# Decoding canonical CBOR payload
decoder = Crystal::Cbor::Fido::Decoder.new(IO::Memory.new(bytes))
decoded_data = decoder.decode
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
- **Project Roadmap**: [`docs/project/roadmap.rst`](docs/project/roadmap.rst)
- **Changelog**: [`CHANGELOG.rst`](CHANGELOG.rst)
- **Code of Honor**: [`docs/technical/CODE_OF_HONOR.rst`](docs/technical/CODE_OF_HONOR.rst)

## License

This project is licensed under the **GNU Affero General Public License v3.0 or later** ([AGPL-3.0-or-later](LICENSE)).
