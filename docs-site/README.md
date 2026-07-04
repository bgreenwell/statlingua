# statlingo unified documentation site

A single [Quarto](https://quarto.org) website unifying documentation for
both the R and Python packages, deployed to GitHub Pages at
<https://bgreenwell.github.io/statlingo/>.

## Structure

- `index.qmd`, `get-started-r.qmd`, `get-started-python.qmd`, `changelog.qmd`
  — hand-written landing/quickstart pages (edit these directly).
- `python/reference/` — **generated** by [quartodoc](https://machow.github.io/quartodoc/)
  from the installed `statlingo` Python package's docstrings. Do not
  hand-edit; re-run `quartodoc build` (see below) after changing Python
  docstrings.
- `_site/r/` — **generated** by R's `pkgdown`, built directly from `r/`
  into this site's output directory as a self-contained subtree. Do not
  hand-edit; re-run `pkgdown::build_site()` (see below) after changing R
  documentation.
- `_quarto.yml` — site config: navbar, theme, and the `quartodoc:` block
  controlling Python API reference generation.

## Building locally

```sh
./scripts/build_docs_site.sh
```

from the repo root, or run the equivalent steps manually:

```sh
# 1. Set up Python + quartodoc (note the griffe pin -- see below)
cd python && uv venv && source .venv/bin/activate
uv pip install -e . chatlas pyyaml quartodoc "griffe<1.0"
cd ../docs-site

# 2. Generate the Python API reference, then render the full site
python3 -m quartodoc build
quarto render .
cd ..

# 3. Build the R reference site directly into docs-site/_site/r -- this
#    MUST run after `quarto render`, which clears _site/ before rendering
#    and would otherwise wipe out the pkgdown site.
Rscript -e 'pkgdown::build_site(pkg = "r", override = list(destination = "../docs-site/_site/r"))'
```

Open `docs-site/_site/index.html` to preview.

## Known issue: `griffe` version pin

`quartodoc` declares a loose `griffe>=0.33` dependency, which resolves to
the latest `griffe` (2.x as of this writing) by default. That release
changed `parse_numpy()`'s signature in a way that's incompatible with
`quartodoc` 0.11.x, causing `quartodoc build` to fail with:
```
TypeError: parse_numpy() got an unexpected keyword argument 'allow_section_blank_line'
```
Pin `griffe<1.0` (as done above and in `.github/workflows/docs-site.yaml`)
until `quartodoc` updates its `griffe` compatibility range.

## CI deployment

`.github/workflows/docs-site.yaml` runs the same steps on every push to
`main` that touches `r/`, `python/`, `prompts/`, or `docs-site/`, and
deploys the result to GitHub Pages (the repo's Pages source is configured
as "GitHub Actions" build type, not the legacy branch/`docs` folder
source).
