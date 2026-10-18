# Configuration file for the Sphinx documentation builder.
# crystal-cbor-fido: Canonical CBOR Encoder and Decoder for FIDO2 and CTAP2

project = 'crystal-cbor-fido'
copyright = '2026, Rénich Bon Ćirić (Copyleft)'
author = 'Rénich Bon Ćirić'
release = '0.2.2'

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.todo',
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'build', 'technical/api', 'Thumbs.db', '.DS_Store']

html_theme = 'sphinx_rtd_theme'
html_static_path = []
html_title = 'crystal-cbor-fido Documentation'
html_show_sourcelink = False
