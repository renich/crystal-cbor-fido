================
Coding Standards
================

Requirement Mapping
-------------------
Fulfills ``[FUNC-001]``, ``[FUNC-002]``, ``[FUNC-003]``, ``[FUNC-005]``.

Core Directives
---------------

#. **Strict Static Analysis**:
   Full default rule sets for Ameba and Flaw are enabled. Global or inline rule suppression (``# ameba:disable`` or ``# flaw:disable``) is strictly prohibited across ``src/`` and ``spec/``. Cyclomatic complexity is capped at 12 (``Metrics/CyclomaticComplexity: MaxComplexity: 12``).

#. **Defensive Nil Handling**:
   Never call ``.not_nil!``. Use explicit type narrowing with ``if``, ``case``, ``unless``, or ``.try``.

#. **Line Length & Formatting**:
   Maximum line length is 120 characters (``Layout/LineLength: MaxLength: 120`` in ``.ameba.yml``), enforced alongside ``crystal tool format --check``.

#. **API Doc Comments**:
   Every public module, class, struct, constant, exception, and method must include concise Markdown doc comments for ``crystal docs`` generation.
