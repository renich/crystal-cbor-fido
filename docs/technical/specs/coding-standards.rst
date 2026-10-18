============================================
[TECH-004] Coding Standards and Quality Gate
============================================

Requirement Mapping
-------------------
Fulfills ``[FUNC-005]``.

Core Directives
---------------

#. **Strict Static Analysis**:
   Full default rule sets for Ameba and Flaw must remain enabled at all times. Global or inline rule suppression (``# ameba:disable`` or ``# flaw:disable``) is forbidden across ``src/`` and ``spec/``. Cyclomatic complexity must not exceed 12 (``Metrics/CyclomaticComplexity: MaxComplexity: 12``).

#. **Defensive Nil and Type Handling**:
   Code must never call ``.not_nil!``. All nilable values and union types must use explicit type narrowing with ``if``, ``case``, ``unless``, or ``.try``, and all method signatures must declare explicit parameter and return type restrictions.

#. **Line Length and Formatting**:
   Maximum line length is 120 characters (``Layout/LineLength: MaxLength: 120`` in ``.ameba.yml``), enforced alongside ``crystal tool format --check src spec``.

#. **API Documentation Coverage**:
   Every public module, class, struct, constant, exception, and method must include concise Markdown doc comments verified via ``crystal docs``.
