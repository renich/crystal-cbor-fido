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
     - :doc:`Business Specifications <business/spec>`
   * - **Functional Specifications**
     - Requirements ``[FUNC-001]``..``[FUNC-007]``, canonical encoding/decoding contracts, and error semantics.
     - :doc:`Functional Specifications <functional/spec>`
   * - **Technical Architecture**
     - Internal architecture ``[TECH-001]``..``[TECH-007]``, IEEE 754 ``Float16`` math, coding standards, threat model, and release playbook.
     - :doc:`Technical Architecture <technical/spec>`
   * - **Architecture Decisions**
     - Immutable Architecture Decision Records and cryptographic serialization trade-off analyses.
     - :doc:`Architecture Decisions <adrs/index>`
   * - **Project Roadmap**
     - Sequenced phase milestones, task dependency graphs, and adversarial audit history.
     - :doc:`Project Roadmap <project/roadmap>`
   * - **User Guides**
     - Integration guides, code examples, and Canonical CBOR serialization tutorials.
     - :doc:`User Manual <user/index>`
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
------------------

* :ref:`genindex`
* :ref:`search`
