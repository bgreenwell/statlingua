#!/usr/bin/env bash
# Build the unified statlingo documentation site (docs-site/_site), combining:
#   - a Quarto-rendered landing/get-started pages + Python API reference
#     (via quartodoc, which introspects the installed `statlingo` Python
#     package's docstrings)
#   - the R package's pkgdown reference site, built directly into
#     docs-site/_site/r/
#
# IMPORTANT ORDERING: `quarto render` clears its output-dir (_site/) before
# rendering, so pkgdown's site MUST be built into _site/r *after* the
# Quarto render step, not before -- otherwise Quarto silently wipes it out.
#
# Requires: R + pkgdown, Python + uv, and Quarto CLI (https://quarto.org)
# installed locally. Mirrors .github/workflows/docs-site.yaml.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "==> Setting up Python env for quartodoc ..."
cd python
uv venv --quiet
source .venv/bin/activate
uv pip install --quiet -e . chatlas pyyaml
# quartodoc's declared `griffe>=0.33` dependency resolves to a too-new,
# API-incompatible griffe release by default (as of quartodoc 0.11.x /
# griffe 2.x) -- pin to the last known-compatible major version.
uv pip install --quiet quartodoc "griffe<1.0"
cd ..

echo "==> Building Python API reference (quartodoc) ..."
cd docs-site
source ../python/.venv/bin/activate
python3 -m quartodoc build

echo "==> Rendering Quarto site ..."
quarto render .
cd ..

echo "==> Building pkgdown site (R) into docs-site/_site/r (after Quarto render, which clears _site/ first) ..."
Rscript -e 'pkgdown::build_site(pkg = "r", override = list(destination = "../docs-site/_site/r"))'

echo "==> Done. Open docs-site/_site/index.html to preview."

