import os
import statsmodels.api as sm
from statlingua import diagnose


def run_diagnose_example():
    """
    Runs an example using a built-in statsmodels dataset (Duncan's Prestige)
    and gets diagnostic advice from statlingua.
    """
    # --- 1. Set up API Key ---
    # Ensure your OPENAI_API_KEY is set in your environment
    if not os.getenv("OPENAI_API_KEY"):
        print("ERROR: Please set your OPENAI_API_KEY environment variable.")
        return

    # --- 2. Load a built-in dataset ---
    # Duncan's Occupational Prestige Dataset contains data on the prestige
    # and other characteristics of 45 U.S. occupations in 1950.
    print("Loading Duncan's Prestige dataset...")
    duncan_data = sm.datasets.get_rdataset("Duncan", "carData")
    df = duncan_data.data

    # The dataset description is available and provides great context for the LLM
    # print(duncan_data.NOTE)

    # --- 3. Fit a multiple regression model ---
    # We'll try to predict 'prestige' based on 'income' and 'education'.
    y = df["prestige"]
    X = df[["income", "education"]]
    X = sm.add_constant(X)  # Add an intercept

    print("Fitting multiple linear regression model...")
    model = sm.OLS(y, X).fit()
    print("Model fitting complete.")

    # --- 4. Use diagnose() to get advice ---
    user_question = (
        "I've fitted a multiple regression model to predict occupational prestige. "
        "How can I tell if this is a good model? What are the most important "
        "assumptions I should check?"
    )

    print(f'\nAsking statlingua to diagnose with the prompt: "{user_question}"')

    advice = diagnose(
        model_object=model,
        prompt=user_question,
        model="gpt-4o",  # Use your preferred model
    )

    # --- 5. Print the result ---
    print("\n--- Statlingua Diagnostic Advice ---")
    print(advice["text"])
    print("------------------------------------")


if __name__ == "__main__":
    run_diagnose_example()
