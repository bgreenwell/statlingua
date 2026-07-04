# agent_example.py
import os
import statsmodels.api as sm
from statlingua import diagnose_agent


def run_agent_example():
    if not os.getenv("OPENAI_API_KEY"):
        print("ERROR: Please set your OPENAI_API_KEY environment variable.")
        return

    print("Loading Duncan's Prestige dataset...")
    duncan_data = sm.datasets.get_rdataset("Duncan", "carData")
    y = duncan_data.data["prestige"]
    X = duncan_data.data[["income", "education"]]
    X = sm.add_constant(X)

    print("Fitting multiple linear regression model...")
    model = sm.OLS(y, X).fit()

    user_question = (
        "Can you check if the relationship in my model is linear and if the "
        "variance of the residuals is constant?"
    )

    print(f'\nAsking agent to diagnose with the prompt: "{user_question}"\n')

    # Use a vision-capable model
    result = diagnose_agent(model_object=model, prompt=user_question, model="gpt-4o")

    print("\n--- Statlingua Agent Response ---")
    print(result["text"])
    print("---------------------------------")
    if result.get("plot"):
        print(f"\nA plot was generated at: {result['plot']}")
        print("You can open this image file to see the plot the agent analyzed.")


if __name__ == "__main__":
    run_agent_example()
