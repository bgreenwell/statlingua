# LLM-as-a-Judge Evaluation System (`evals/`)

This directory contains the assets for testing and grading `statlingo`'s natural language explanations using an LLM-as-a-Judge system.

---

## Where Are Evals Sent?
Evaluation scores are **not sent to any external dashboard or tracking service**. They are printed directly to the console (`stdout`). When run as part of the GitHub Actions CI pipeline, they are logged in the runner workflow output.

---

## How It Works
The evaluation suite uses a dual-LLM approach:
1. **Generator**: Takes a mock statistical model's summary output and uses `statlingo`'s prompt interpolation to produce a structured natural language explanation.
2. **Judge**: Takes the generated explanation and evaluates it against a structured `ground_truth` JSON block using the system instructions defined in [judge_prompt.md](judge_prompt.md).

The Judge grades the explanation on three criteria on a scale of `1` (poor) to `5` (excellent):
- **Factuality**: Are the statistics and coefficients correctly stated?
- **Audience Alignment**: Is the tone/pedagogy correctly tuned for the target audience?
- **Hallucination**: Does the explanation mention fields, metrics, or contexts not supported by the ground-truth stats?

If any criterion falls below `3/5` for any test case, the evaluation run fails (exit code `1`).

---

## Running Evaluations Locally

Ensure your `GEMINI_API_KEY` (or `GOOGLE_API_KEY`) is set, then execute the runner script from the repository root:

```bash
# Activate your Python virtual environment
source python/.venv/bin/activate

# Run the evals suite
python3 scripts/run_evals.py
```

---

## How to Add a New Test Case

Follow these steps to add a test case for a new model or family:

### 1. Generate the Raw Summary Output
Write a quick script to fit your model and print its summary. For example:
```python
import statsmodels.api as sm
# Fit your model here...
print(model.summary())
```

### 2. Create the Case JSON File
Create a new JSON file in `evals/cases/` (e.g. `evals/cases/my_model.json`). Use the following structure:

```json
{
  "model_type": "name_of_the_prompt_folder",
  "engine": "statsmodels_or_other_engine",
  "summary": "Paste the exact multiline string output from step 1 here",
  "ground_truth": {
    "dependent_variable": "y",
    "observations": 20,
    "coefficients": {
      "const": {
        "coef": 1.23,
        "std_err": 0.45,
        "p_value": 0.01,
        "significant": true
      }
    },
    "diagnostics": {
      "aic": 123.4
    }
  }
}
```

> [!IMPORTANT]
> **List All Summary Fields in Ground Truth**: The Judge is extremely strict about the **Hallucination** score. If the generator correctly explains a field (e.g. a convergence flag, degrees of freedom, or diagnostic test) that was in the raw `summary` but was omitted from your `"ground_truth"` JSON block, the Judge will flag it as a hallucination. Make sure all numbers and metrics present in your raw summary are documented under `"ground_truth"`.
