#!/usr/bin/env python3
import os
import json
import glob
import sys
from chatlas import ChatGoogle

# Ensure the package in the python/ directory can be imported
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "python", "src")))

from statlingo import explain

# Custom mock object for OLS model to pass to explain()
class DummyModel:
    def __init__(self, summary_text):
        self.summary_text = summary_text

# Register handler for DummyModel so we can pass it directly to explain()
from statlingo.model_handlers import register_handler
@register_handler(DummyModel)
def dummy_handler(model):
    return "DummyModel", "statsmodels", model.summary_text

def run_evals():
    if not os.getenv("GEMINI_API_KEY") and not os.getenv("GOOGLE_API_KEY"):
        print("ERROR: Please set your GEMINI_API_KEY or GOOGLE_API_KEY environment variable.")
        sys.exit(1)

    # 1. Load judge prompt
    judge_prompt_path = os.path.join(os.path.dirname(__file__), "..", "evals", "judge_prompt.md")
    with open(judge_prompt_path, "r") as f:
        judge_system_prompt = f.read()

    # 2. Find all test cases
    cases_dir = os.path.join(os.path.dirname(__file__), "..", "evals", "cases")
    case_files = glob.glob(os.path.join(cases_dir, "*.json"))
    if not case_files:
        print(f"No test cases found in {cases_dir}")
        sys.exit(1)

    print(f"Found {len(case_files)} evaluation test cases.")

    # Create clients
    generator_client = ChatGoogle()
    judge_client = ChatGoogle(system_prompt=judge_system_prompt)

    results = []
    failed = False

    for case_file in case_files:
        print(f"\nEvaluating {os.path.basename(case_file)}...")
        with open(case_file, "r") as f:
            case_data = json.load(f)

        # Instantiate DummyModel with the OLS summary
        model = DummyModel(case_data["summary"])

        # target config
        audience = "student"
        verbosity = "detailed"

        # Generate explanation
        print("Generating explanation...")
        explanation_res = explain(
            model_object=model,
            client=generator_client,
            audience=audience,
            verbosity=verbosity
        )
        generated_text = explanation_res["text"]

        # Run Judge
        print("Running Judge evaluation...")
        judge_input = f"""
### Target Configuration:
Audience: {audience}
Verbosity: {verbosity}

### Ground Truth Stats:
{json.dumps(case_data["ground_truth"], indent=2)}

### Generated Explanation:
{generated_text}
"""
        judge_response_raw = judge_client.chat(judge_input)
        
        # Clean up code fences if present in JSON response
        judge_response_clean = str(judge_response_raw).strip()
        if judge_response_clean.startswith("```json"):
            judge_response_clean = judge_response_clean[7:]
        if judge_response_clean.endswith("```"):
            judge_response_clean = judge_response_clean[:-3]
        judge_response_clean = judge_response_clean.strip()

        try:
            scores = json.loads(judge_response_clean)
        except Exception as e:
            print(f"Failed to parse Judge JSON response: {e}")
            print(f"Raw response: {judge_response_raw}")
            scores = {
                "factuality": 1,
                "audience_alignment": 1,
                "hallucination": 1,
                "explanation": f"Failed to parse Judge response: {e}"
            }

        case_name = os.path.basename(case_file).replace(".json", "")
        results.append({
            "case": case_name,
            "audience": audience,
            "verbosity": verbosity,
            "scores": scores
        })

        print(f"Scores for {case_name}:")
        print(f"  Factuality: {scores.get('factuality')}/5")
        print(f"  Audience Alignment: {scores.get('audience_alignment')}/5")
        print(f"  Hallucination: {scores.get('hallucination')}/5")
        print(f"  Explanation: {scores.get('explanation')}")

        # Check if any score is less than 3
        if scores.get("factuality", 0) < 3 or scores.get("audience_alignment", 0) < 3 or scores.get("hallucination", 0) < 3:
            failed = True

    # Print summary table
    print("\n" + "="*50)
    print("EVALUATION RESULTS SUMMARY")
    print("="*50)
    print(f"{'Case':<15} | {'Audience':<10} | {'Factuality':<10} | {'Alignment':<10} | {'Hallucination':<13}")
    print("-"*68)
    for r in results:
        print(f"{r['case']:<15} | {r['audience']:<10} | {r['scores'].get('factuality'):<10} | {r['scores'].get('audience_alignment'):<10} | {r['scores'].get('hallucination'):<13}")
    print("="*50)

    if failed:
        print("\n❌ Evals FAILED: One or more criteria fell below threshold of 3/5.")
        sys.exit(1)
    else:
        print("\n✅ Evals PASSED: All criteria met threshold of >= 3/5.")
        sys.exit(0)

if __name__ == "__main__":
    run_evals()
