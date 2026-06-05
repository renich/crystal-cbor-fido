# crystal-cbor-fido

A secure, constant-time, and strictly compliant FIDO CBOR implementation for Crystal.

## Features
- Fully compliant with FIDO Canonical CBOR encoding/decoding specifications.
- Memory safe: strict bounds checking, depth limits, and Duplicate Key rejection.
- Cryptographically secure: uses SipHash-2-4 for map keys to prevent DoS attacks.

## Usage
Add this to your application's `shard.yml`:
```yaml
dependencies:
  crystal-cbor-fido:
    github: renich/crystal-cbor-fido
```

## Documentation
Full architectural and API documentation is available in the `docs/` directory. Use `make docs` to generate the HTML.

## Credits
- **Co-developed-by**: Gemini AI <renich+gemini@woralelandia.com>
- **Signed-off-by**: Rénich Bon Ćirić <renich@woralelandia.com>

## Code of Honor
This project strictly adheres to the [Code of Honor](docs/technical/CODE_OF_HONOR.rst) drafted by Rénich Bon Ćirić.
