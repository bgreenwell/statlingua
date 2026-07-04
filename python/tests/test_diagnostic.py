# tests/test_diagnostic.py

import os
import copy
import pytest
import statsmodels.api as sm
import numpy as np

from statlingo.diagnostic import diagnose, diagnose_agent


class MockChat:
    def __init__(self, response_text: str = "Mock response"):
        self._turns = []
        self._system_prompt = None
        self.response_text = response_text
        self.registered_tools = []
        self.recorder = {
            "last_user_prompt": None,
            "last_system_prompt": None,
            "call_count": 0,
        }

    def set_turns(self, turns):
        self._turns = list(turns)

    @property
    def system_prompt(self):
        return self._system_prompt

    @system_prompt.setter
    def system_prompt(self, value):
        self._system_prompt = value

    def register_tool(self, tool):
        self.registered_tools.append(tool)

    def chat(self, prompt, *args, **kwargs):
        self.recorder["last_user_prompt"] = prompt
        self.recorder["last_system_prompt"] = self._system_prompt
        self.recorder["call_count"] += 1
        
        # Simulate tool execution if the tool is registered
        if self.registered_tools:
            for tool in self.registered_tools:
                # Execute the tool function to simulate tool calling
                tool()
        
        return self.response_text

    def __deepcopy__(self, memo):
        new = MockChat.__new__(MockChat)
        memo[id(self)] = new
        new._turns = copy.deepcopy(self._turns, memo)
        new._system_prompt = self._system_prompt
        new.response_text = self.response_text
        new.registered_tools = self.registered_tools  # shared reference: NOT copied
        new.recorder = self.recorder  # shared reference
        return new


def _fit_ols():
    rng = np.random.default_rng(0)
    x = sm.add_constant(rng.random(20))
    y = 2 + 3 * x[:, 1] + rng.normal(size=20)
    model = sm.OLS(y, x).fit()
    # Add dummy attributes just in case
    if not hasattr(model, "resid"):
        model.resid = np.random.normal(size=20)
    if not hasattr(model, "fittedvalues"):
        model.fittedvalues = np.random.normal(size=20)
    return model


def test_diagnose_calls_chat_correctly():
    mock_chat = MockChat("This is mock diagnostic advice.")
    model = _fit_ols()

    result = diagnose(
        model_object=model,
        client=mock_chat,
        prompt="Is the model valid?",
    )

    assert mock_chat.recorder["call_count"] == 1
    assert "Is the model valid?" in mock_chat.recorder["last_user_prompt"]
    assert "You are an expert statistical consultant." in mock_chat.recorder["last_system_prompt"]
    assert result["text"] == "This is mock diagnostic advice."


def test_diagnose_agent_workflow():
    mock_chat = MockChat("This is visual analysis.")
    model = _fit_ols()

    # Remove residual_plot.png if it exists
    if os.path.exists("residual_plot.png"):
        os.remove("residual_plot.png")

    result = diagnose_agent(
        model_object=model,
        client=mock_chat,
        prompt="Check residuals.",
    )

    # In our MockChat simulation:
    # 1. First chat call registers the tool.
    # 2. In chat(), it iterates over registered tools and runs them, which generates "residual_plot.png".
    # 3. diagnose_agent checks if "residual_plot.png" exists, and makes a second chat call to interpret it.
    # So call count should be 2.
    assert mock_chat.recorder["call_count"] == 2
    assert len(mock_chat.registered_tools) == 1
    assert os.path.exists("residual_plot.png")
    assert result["text"] == "This is visual analysis."
    assert result["plot"] == "residual_plot.png"

    # Clean up
    if os.path.exists("residual_plot.png"):
        os.remove("residual_plot.png")
