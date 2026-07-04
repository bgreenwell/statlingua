# statlingo (Python)

[![Python tests](https://github.com/bgreenwell/statlingo/actions/workflows/python-tests.yaml/badge.svg)](https://github.com/bgreenwell/statlingo/actions/workflows/python-tests.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

An experimental Python package to help you understand statistical models using
the power of large language models (LLMs).

> **Note:** This package is under active development. The API is subject to
> change, and users should expect rapid evolution of features.

This package translates the complex output of statistical models into clear,
human-readable explanations. It is designed for students, researchers, and
data scientists who want to gain a deeper intuition for their models.

This is the Python counterpart to the [R package `statlingo`](../r); both
share the same underlying prompt content (see [`../prompts/`](../prompts)) and
target parity for the `explain()` workflow.

## Core features

  * **Explain model results:** Get detailed, context-aware explanations of
    your model's summary output using the `explain()` function.
  * **Powered by modern LLMs:** Uses [`chatlas`](https://posit-dev.github.io/chatlas/)
    to talk to any supported provider (OpenAI, Anthropic, Google, and more)
    through a single, consistent `Chat` client interface.
  * **Extensible by design:** Built to be easily extended with support for
    new statistical models via a simple handler registry.

> Agentic, tool-calling diagnostic features (`diagnose()`/`diagnose_agent()`)
> that previously lived here have been moved to
> [`experimental/`](experimental) while this package focuses on bringing
> `explain()` to parity with the R implementation. They are not part of the
> public API for now.

## Installation

From PyPI (once published):

```sh
pip install statlingo
```

Or install the development version directly from GitHub:

```sh
pip install "git+https://github.com/bgreenwell/statlingo.git#subdirectory=python"
```

You will also need `statsmodels` (for fitting the example models below) and a
[`chatlas`-supported provider SDK](https://posit-dev.github.io/chatlas/get-started/models.html)
(e.g. `openai` for `ChatOpenAI`).

## Quick start

Before running, make sure you have set your `OPENAI_API_KEY` (or the key for
your preferred provider) as an environment variable.

```python
import os
import statsmodels.api as sm
from chatlas import ChatOpenAI
from statlingo import explain

# Ensure your API key is set
# export OPENAI_API_KEY="sk-..."

if not os.getenv("OPENAI_API_KEY"):
    raise EnvironmentError("Please set your OPENAI_API_KEY environment variable.")

# 1. Load data and fit a model (Duncan's occupational prestige data)
duncan_data = sm.datasets.get_rdataset("Duncan", "carData")
y = duncan_data.data['prestige']
X = duncan_data.data[['income', 'education']]
X = sm.add_constant(X)
model = sm.OLS(y, X).fit()

# 2. Create a chatlas Chat client (never mutated by explain())
client = ChatOpenAI(model="gpt-4o")

# 3. Get a high-level explanation of the model results
explanation = explain(
    model_object=model,
    client=client,
    audience="student",
)
print(explanation["text"])
```

## Contributing

Contributions are welcome! If you have suggestions for new features, find a
bug, or want to add support for a new model, please open an issue on the
GitHub repository.

## License

This project is licensed under the GNU General Public License v3.0 (GNU GPLv3).
