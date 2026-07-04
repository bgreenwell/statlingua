import matplotlib.pyplot as plt
import seaborn as sns
import base64
import os

from typing import Any
import litellm

from .model_handlers import get_handler


def diagnose(
    model_object: Any,
    prompt: str,
    model: str,
    **kwargs: Any,
) -> dict:
    """
    Provides advice on diagnosing a statistical model's assumptions.

    This function acts as a first step towards an agentic assistant. It takes
    a fitted model and a user's question about diagnostics, and returns
    text-based advice on what checks to perform.

    Parameters
    ----------
    model_object : Any
        A fitted statistical model object.
    prompt : str
        The user's question about model diagnostics (e.g., "Is this a good model?").
    model : str
        The model string for the LLM provider (e.g., "gpt-4o").
    **kwargs : Any
        Additional keyword arguments to pass to `litellm.completion`.

    Returns
    -------
    dict
        A dictionary containing the LLM's diagnostic advice.
    """
    # 1. Get the model's summary using the existing handler system
    handler = get_handler(model_object)
    model_name, summary_text = handler(model_object)

    # 2. Create a system prompt that primes the LLM for diagnostics
    system_prompt = (
        "You are an expert statistical consultant. Your goal is to help a user "
        "diagnose the assumptions of their statistical model. Based on the user's "
        "question and the model summary, provide clear, actionable advice on "
        "what diagnostic checks they should perform. Recommend specific plots "
        "(e.g., 'a residuals vs. fitted plot to check for non-linearity') or "
        "statistical tests (e.g., 'calculate Variance Inflation Factors (VIFs) "
        "to check for multicollinearity')."
    )

    # 3. Create the user prompt
    user_prompt = (
        f'My Question: "{prompt}"\n\n'
        f"Here is the summary of my {model_name} model:\n\n---\n{summary_text}"
    )

    # 4. Call the LLM
    response = litellm.completion(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        **kwargs,
    )

    # 5. Return the response
    return {"text": response.choices[0].message.content}


# --- Agentic Tools ---


def plot_residuals_vs_fitted(model_object: Any) -> str:
    """
    Generates and saves a residuals vs. fitted values plot.

    Parameters
    ----------
    model_object : Any
        A fitted statsmodels model object that has .resid and .fittedvalues attributes.

    Returns
    -------
    str
        The filepath of the saved plot image.
    """
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

        # Save the plot to a file
        filepath = "residual_plot.png"
        plt.savefig(filepath)
        plt.close()  # Close the plot to free up memory

        print(f"Tool executed: Generated plot at '{filepath}'")
        return filepath

    except Exception as e:
        return f"Error executing plot_residuals_vs_fitted: {e}"


# --- Tool Definitions for the LLM ---

tools = [
    {
        "type": "function",
        "function": {
            "name": "plot_residuals_vs_fitted",
            "description": "Generates a scatter plot of model residuals versus fitted values to check for non-linearity and heteroscedasticity.",
            "parameters": {"type": "object", "properties": {}, "required": []},
        },
    }
]

# A dictionary to map tool names to the actual Python functions
available_tools = {
    "plot_residuals_vs_fitted": plot_residuals_vs_fitted,
}


def diagnose_agent(
    model_object: Any,
    prompt: str,
    model: str,
    **kwargs: Any,
):
    """
    Diagnoses a model using an agentic, tool-based approach.
    """
    # 1. First call to the LLM to decide on a course of action
    system_prompt = (
        "You are an expert statistical consultant. Your goal is to help a user "
        "diagnose the assumptions of their statistical model. Based on the user's "
        "question, decide if one of your available tools can help answer it. "
        "If so, call the appropriate tool. If not, provide a text-based answer."
    )

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": prompt},
    ]

    print("Agent: Thinking about the user's request...")
    response = litellm.completion(model=model, messages=messages, tools=tools, **kwargs)

    response_message = response.choices[0].message
    tool_calls = response_message.tool_calls

    if not tool_calls:
        print("Agent: No tool needed. Responding directly.")
        return {"text": response_message.content, "plot": None}

    # Append the assistant's decision to use a tool to the conversation
    messages.append(response_message)

    # 2. Execute the tool call(s)
    tool_call = tool_calls[0]
    function_name = tool_call.function.name

    if function_name in available_tools:
        print(f"Agent: Decided to use the tool '{function_name}'.")
        function_to_call = available_tools[function_name]
        tool_output_filepath = function_to_call(model_object)

        # 3. Append the REQUIRED 'tool' message to the conversation
        # This message tells the LLM the result of the tool call it requested.
        messages.append(
            {
                "role": "tool",
                "tool_call_id": tool_call.id,
                "name": function_name,
                "content": f"Tool '{function_name}' executed successfully. The resulting plot has been generated at '{tool_output_filepath}'. Now, I will analyze it.",
            }
        )

    else:
        return {"text": f"Error: Tool '{function_name}' not found.", "plot": None}

    # --- 4. Second call to the LLM to interpret the result ---

    # Read the image and encode it to be sent for visual analysis
    with open(tool_output_filepath, "rb") as image_file:
        base64_image = base64.b64encode(image_file.read()).decode("utf-8")

    # Now, append the user message that includes the image for analysis
    messages.append(
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Please analyze the plot that was just generated and interpret it for me.",
                },
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:image/png;base64,{base64_image}"},
                },
            ],
        }
    )

    print("Agent: Sending plot to the LLM for interpretation...")

    # Use a vision-capable model for the final interpretation
    final_response = litellm.completion(model=model, messages=messages, **kwargs)

    return {
        "text": final_response.choices[0].message.content,
        "plot": tool_output_filepath,
    }
