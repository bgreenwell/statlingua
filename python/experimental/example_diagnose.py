import os
import statsmodels.api as sm
from chatlas import ChatGoogle
from statlingo import diagnose


def run_diagnose_example():
    """
    Runs an example using a built-in statsmodels dataset (Duncan's Prestige)
    and gets diagnostic advice from statlingo.
    """
    # --- 1. Set up API Key ---
    if not os.getenv("GEMINI_API_KEY") and not os.getenv("GOOGLE_API_KEY"):
        print("ERROR: Please set your GEMINI_API_KEY or GOOGLE_API_KEY environment variable.")
        return

    # --- 2. Load a built-in dataset ---
    print("Loading Duncan's Prestige dataset...")
    duncan_data = sm.datasets.get_rdataset("Duncan", "carData")
    df = duncan_data.data

    # --- 3. Fit a multiple regression model ---
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

    print(f'\nAsking statlingo to diagnose with the prompt: "{user_question}"')

    # Create a ChatGoogle client
    client = ChatGoogle()

    advice = diagnose(
        model_object=model,
        client=client,
        prompt=user_question,
    )

    # --- 5. Print the result ---
    print("\n--- Statlingo Diagnostic Advice ---")
    print(advice["text"])
    print("------------------------------------")


if __name__ == "__main__":
    run_diagnose_example()

