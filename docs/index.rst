===================================
Crystal CBOR FIDO Documentation Hub
===================================

**Canonical RFC 8949 Section 4.2 and FIDO2 CTAP2 Section 6 CBOR Encoder and Decoder for Crystal.**

Welcome to the official documentation portal for ``crystal-cbor-fido``.

Documentation Architecture
--------------------------

.. list-table::
   :widths: 25 45 30
   :header-rows: 1

   * - Guide
     - Purpose & Scope
     - Entrypoint
   * - **Business & Strategy**
     - Strategic vision, FIDO2/WebAuthn ecosystem goals, and user personas.
     - `Business Specifications <business/spec.rst>`__
   * - **Functional Specifications**
     - Requirements ``[FUNC-001]``..``[FUNC-006]``, canonical encoding/decoding contracts, and error semantics.
     - `Functional Specifications <functional/spec.rst>`__
   * - **Technical Architecture**
     - Internal architecture, IEEE 754 ``Float16`` math, coding standards, threat model, and release playbook.
     - `Technical Architecture <technical/spec.rst>`__
   * - **Architecture Decisions**
     - Immutable Architecture Decision Records and cryptographic serialization trade-off analyses.
     - `Architecture Decisions <adrs/index.rst>`__
   * - **Project Roadmap**
     - Sequenced phase milestones, delivery tracking, and adversarial audit history.
     - `Project Roadmap <project/roadmap.rst>`__
   * - **User Guides**
     - Integration guides, code examples, and Canonical CBOR serialization tutorials.
     - `User Manual <user/index.rst>`__
   * - **Crystal API Reference**
     - Compiler-generated API documentation covering all modules, classes, structs, and exceptions.
     - `Crystal API Reference <technical/api/index.html>`__

.. toctree::
   :maxdepth: 2
   :caption: Documentation Suite

   business/spec
   functional/spec
   technical/spec
   adrs/index
   project/roadmap
   user/index

Indices and tables
==================

* :ref:`genindex`
* :ref:`search`
