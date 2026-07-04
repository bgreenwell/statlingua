# src/statlingo/diagnostic.py

import os
import copy
from typing import Any, Optional

try:
    import matplotlib.pyplot as plt
    import seaborn as sns
    HAS_PLOT_DEPS = True
except ImportError:
    HAS_PLOT_DEPS = False

from chatlas import content_image_file
from .model_handlers import get_handler


def diagnose(
    model_object: Any,
    client: Any,
    prompt: str,
) -> dict:
    """Provides advice on diagnosing a statistical model's assumptions.

    Parameters
    ----------
    model_object : Any
        A fitted statistical model object.
    client : chatlas.Chat
        A chatlas Chat client (e.g. ChatGoogle or ChatOpenAI).
    prompt : str
        The user's question about model diagnostics.

    Returns
    -------
    dict
        A dictionary containing the LLM's diagnostic advice.
    """
    # Get the model's summary using the existing handler system
    handler = get_handler(model_object)
    model_name, engine, summary_text = handler(model_object)

    # Create a system prompt that primes the LLM for diagnostics
    system_prompt = (
        "You are an expert statistical consultant. Your goal is to help a user "
        "diagnose the assumptions of their statistical model. Based on the user's "
        "question and the model summary, provide clear, actionable advice on "
        "what diagnostic checks they should perform. Recommend specific plots "
        "(e.g., 'a residuals vs. fitted plot to check for non-linearity') or "
        "statistical tests (e.g., 'calculate Variance Inflation Factors (VIFs) "
        "to check for multicollinearity')."
    )

    user_prompt = (
        f'My Question: "{prompt}"\n\n'
        f"Here is the summary of my {model_name} model:\n\n---\n{summary_text}"
    )

    # Clone the client to avoid side effects on the user's client
    temp_chat = copy.deepcopy(client)
    temp_chat.set_turns([])
    temp_chat.system_prompt = system_prompt

    response = temp_chat.chat(user_prompt, echo="none", stream=False)

    return {"text": str(response)}


def diagnose_agent(
    model_object: Any,
    client: Any,
    prompt: str,
) -> dict:
    """Diagnoses a model using an agentic, tool-based approach with chatlas.

    Parameters
    ----------
    model_object : Any
        A fitted statistical model object.
    client : chatlas.Chat
        A chatlas Chat client (e.g. ChatGoogle or ChatOpenAI).
    prompt : str
        The user's question about model diagnostics.

    Returns
    -------
    dict
        A dictionary containing the LLM's diagnostic response and the generated plot path.
    """
    if not HAS_PLOT_DEPS:
        raise ImportError(
            "The diagnose_agent function requires matplotlib and seaborn. "
            "Please install them with `pip install matplotlib seaborn`."
        )

    # 1. Create a deep copy of the client to avoid mutating the user's client
    temp_chat = copy.deepcopy(client)
    temp_chat.set_turns([])  # clear any history

    plot_filepath = "residual_plot.png"
    # Ensure no stale plot file exists
    if os.path.exists(plot_filepath):
        try:
            os.remove(plot_filepath)
        except Exception:
            pass

    # Define the tool in the closure
    def plot_residuals_vs_fitted() -> str:
        """Generates a scatter plot of model residuals versus fitted values to check for non-linearity and heteroscedasticity."""
        try:
            residuals = model_object.resid
            fitted = model_object.fittedvalues

            plt.figure(figsize=(8, 6))
            sns.residplot(
                x=fitted,
                y=residuals,
                lowess=True,
                scatter_kws={"alpha": 0.5},
                line_kws={"color": "red", "lw": 2, "alpha": 0.8},
            )
            plt.title("Residuals vs. Fitted Plot")
            plt.xlabel("Fitted values")
            plt.ylabel("Residuals")

            plt.savefig(plot_filepath)
            plt.close()

            return f"Generated residuals vs fitted plot successfully at '{plot_filepath}'."
        except Exception as e:
            return f"Error executing plot_residuals_vs_fitted: {e}"

    # Register the tool
    temp_chat.register_tool(plot_residuals_vs_fitted)

    # Prime the LLM for agentic tool use
    system_prompt = (
        "You are an expert statistical consultant. Your goal is to help a user "
        "diagnose the assumptions of their statistical model. Based on the user's "
        "question, decide if one of your available tools can help answer it. "
        "If you need a residuals vs fitted plot, call the appropriate tool. "
        "After the tool returns, describe its outcome in text. "
        "If no tool is needed, provide a direct text response."
    )
    temp_chat.system_prompt = system_prompt

    user_prompt = f"My Question: {prompt}"

    print("Agent: Thinking about the user's request...")
    response = temp_chat.chat(user_prompt, echo="none", stream=False)

    # 2. Check if a plot was generated by the tool
    if os.path.exists(plot_filepath):
        print("Agent: Plot generated by tool. Sending plot to the LLM for interpretation...")
        # Send the image back to the model for visual analysis
        final_prompt = "Here is the generated plot. Please analyze the plot that was just generated and interpret it for me."
        final_response = temp_chat.chat(
            final_prompt,
            content_image_file(plot_filepath, resize="high"),
            echo="none",
            stream=False
        )
        return {
            "text": str(final_response),
            "plot": plot_filepath
        }
    else:
        print("Agent: No plot generated. Responding directly.")
        return {
            "text": str(response),
            "plot": None
        }
