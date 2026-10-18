=========================================
Release Procedure and Versioning Playbook
=========================================

Overview
--------
This document defines the deterministic, repeatable release workflow for ``crystal-cbor-fido``. It enforces Semantic Versioning 2.0.0, Keep a Changelog 1.1.0 compliance, multi-file version alignment, local pre-push linting, signed GPG Git tags, and automated GitLab CI verification.

Requirement Mapping
-------------------
Fulfills ``[FUNC-005]``.

Multi-File Version Alignment Checklist
--------------------------------------
Prior to tagging any release, the version string (e.g., ``0.2.1``) must be updated in four locations across the codebase:

#. **`shard.yml <../../../shard.yml>`__**:

   .. code-block:: yaml

      version: 0.2.1

#. **`src/crystal-cbor-fido.cr <../../../src/crystal-cbor-fido.cr>`__**:

   .. code-block:: crystal

      VERSION = "0.2.1"

#. **`docs/conf.py <../../conf.py>`__**:

   .. code-block:: python

      release = '0.2.1'

#. **`CHANGELOG.rst <../../../CHANGELOG.rst>`__**:
   Promote items from ``[Unreleased]`` under a new version header using ``.. rubric::`` sections:

   .. code-block:: rst

      [0.2.1] - 2026-10-18
      ====================

      .. rubric:: Added

      - Full Sphinx documentation portal and modular specification hierarchy.

Step-by-Step Release Execution Playbook
---------------------------------------

Step 1: Local Quality Assurance and Spec Verification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Execute the full test suite, static analyzers, and documentation linters locally:

.. code-block:: bash

   make all
   make doc-check
   make docs

All specs must pass with 0 failures, 0 errors, 0 Ameba lint issues, 0 Flaw security findings, 0 ``crstlint`` warnings, and 0 ``rstcheck`` warnings.

Step 2: Commit Version Bump and Changelog Update
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Stage and commit version changes adhering to Conventional Commit standards:

.. code-block:: bash

   git add shard.yml src/crystal-cbor-fido.cr spec/crystal-cbor-fido_spec.cr docs/conf.py CHANGELOG.rst
   git commit -m "chore(release): bump version to v0.2.1"

Step 3: Create Signed Annotated Git Tag
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Create a GPG-signed Git tag for the release:

.. code-block:: bash

   git tag -s v0.2.1 -m "Release v0.2.1"

Step 4: Push Branch and Tags to GitLab
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Push the release commit and tag to the remote GitLab repository:

.. code-block:: bash

   git push origin master --tags

Step 5: Automated GitLab CI Verification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Pushing to ``master`` and tagging ``v0.2.1`` triggers the GitLab CI pipeline in `.gitlab-ci.yml <../../../.gitlab-ci.yml>`__, executing format verification, Ameba, Flaw, and the full spec suite in a clean Alpine Linux environment.
