=================================
Contributing to crystal-cbor-fido
=================================

Thank you for your interest in contributing to ``crystal-cbor-fido``. We welcome contributions from human engineers and autonomous agents who share our commitment to software excellence, cryptographic rigor, and empirical verification.

Code of Honor
=============

All contributors must uphold the principles defined in `CODE_OF_HONOR.rst <CODE_OF_HONOR.rst>`__. We build resilient, well-tested software, demand intellectual honesty, operate transparently, and verify all library behaviors empirically.

Development Workflow
====================

Prerequisites
-------------

* `Crystal <https://crystal-lang.org/>`__ >= 1.21.0
* `GNU Make <https://www.gnu.org/software/make/>`__
* `Sphinx <https://www.sphinx-doc.org/>`__ ``sphinx-build``
* `cRSTLint <https://gitlab.com/renich/crstlint>`__ and ``rstcheck`` for documentation linting

Setting Up the Workspace
------------------------

#. Clone the repository:

   .. code-block:: bash

      git clone git@gitlab.com:renich/crystal-cbor-fido.git
      cd crystal-cbor-fido

#. Build the linter binaries and run the full quality suite:

   .. code-block:: bash

      make deps
      make all
      make doc-check
      make docs

Testing and Quality Standards
=============================

We adhere strictly to Test-Driven Development and the principle of **Do Not Assume; Always Verify**.

Running Checks
--------------

* **Run test suite**:

   .. code-block:: bash

      make test

* **Run static linters** ``crystal tool format --check``, Ameba, and Flaw:

   .. code-block:: bash

      make lint

* **Validate RST Documentation**:

   .. code-block:: bash

      make doc-check

* **Build Sphinx and Crystal API Documentation**:

   .. code-block:: bash

      make docs

Git Commit Standards
====================

We enforce the Conventional Commits specification:

* ``feat(encoder): add canonical float16 serialization``
* ``fix(decoder): reject non-minimal integer encodings``
* ``docs(adrs): record decision on zero external dependencies``
* ``test(spec): add adversarial allocation budget specs``

All commits must be signed and authored with full technical ownership.
