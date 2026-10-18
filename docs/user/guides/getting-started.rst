===============
Getting Started
===============

Installation
------------

Add ``crystal-cbor-fido`` to your project's ``shard.yml``:

.. code-block:: yaml

   dependencies:
     crystal-cbor-fido:
       gitlab: renich/crystal-cbor-fido
       version: ~> 0.2.2

Install dependencies:

.. code-block:: bash

   shards install

Compile-Time CBOR::Serializable Models
--------------------------------------

Annotate Crystal structs or classes with ``include CBOR::Serializable`` and ``@[CBOR::Field]`` to synthesize deterministic CTAP2 canonical CBOR serialization:

.. code-block:: crystal

   require "crystal-cbor-fido"

   struct CoseEc2Key
     include CBOR::Serializable

     @[CBOR::Field(key: 1_i64)]
     getter kty : Int64

     @[CBOR::Field(key: 3_i64)]
     getter alg : Int64

     @[CBOR::Field(key: -1_i64)]
     getter crv : Int64

     def initialize(@kty : Int64, @alg : Int64, @crv : Int64) : Nil
     end
   end

   key = CoseEc2Key.new(kty: 2_i64, alg: -7_i64, crv: 1_i64)
   bytes = key.to_cbor
   restored = CoseEc2Key.from_cbor(bytes)

Dynamic Value Maps and Streaming IO
-----------------------------------

Require the library and encode or decode Canonical CBOR payloads over ``Bytes`` slices or bounded ``IO`` streams:

.. code-block:: crystal

   require "crystal-cbor-fido"

   # Build a CBOR map using the recursive Value union
   cose_key = Hash(Crystal::Cbor::Fido::Value, Crystal::Cbor::Fido::Value).new
   cose_key[1_i64] = 2_i64          # kty: EC2
   cose_key[3_i64] = -7_i64         # alg: ES256
   cose_key[-1_i64] = 1_i64         # crv: P-256
   cose_key["rp_id"] = "example.mx"

   # Encode into deterministic Canonical CBOR bytes or directly to an IO
   bytes = Crystal::Cbor::Fido.encode(cose_key)
   puts bytes.hexstring

   # Decode and validate canonical CBOR bytes or bounded IO stream
   decoded = Crystal::Cbor::Fido.decode(IO::Memory.new(bytes), max_bytes: 65_536_u64, eof_check: true)
   puts decoded.inspect

Error Handling
--------------

Rescue domain-specific exceptions to distinguish canonical violations and nesting depth limits from general framing errors:

.. code-block:: crystal

   begin
     # Non-minimal 1-byte integer encoding (0x18 0x05 instead of 0x05)
     Crystal::Cbor::Fido.decode(Bytes[0x18, 0x05])
   rescue ex : Crystal::Cbor::Fido::CanonicalError
     STDERR.puts "Canonical CBOR violation: #{ex.message}"
   rescue ex : Crystal::Cbor::Fido::DepthError
     STDERR.puts "Container nesting limit exceeded: #{ex.message}"
   rescue ex : Crystal::Cbor::Fido::CborError
     STDERR.puts "Malformed CBOR payload: #{ex.message}"
   end
