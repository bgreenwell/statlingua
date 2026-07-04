# tests/test_explain.py

import copy

import numpy as np
import statsmodels.api as sm

from statlingua.explain import explain


class MockChat:
    """A minimal test double matching chatlas.Chat's public surface used by
    ``explain()``: ``set_turns()``, a settable ``system_prompt`` property,
    and ``chat()``.

    ``explain()`` calls ``copy.deepcopy(client)`` before use (chatlas's own
    documented pattern for forking a Chat without mutating the caller's
    object -- see ``_chat_once()`` in ``statlingua.explain``), so any state
    recorded during ``chat()`` happens on the *deep copy*, not the original
    mock instance held by the test. To make that state observable, a
    ``recorder`` dict is deliberately kept as a *shared reference* (not
    deep-copied) via a custom ``__deepcopy__``.
    """

    def __init__(self, response_text: str = "This is a mock explanation."):
        self._turns = []
        self._system_prompt = None
        self.response_text = response_text
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

    def chat(self, prompt, echo="none", stream=False):
        self.recorder["last_user_prompt"] = prompt
        self.recorder["last_system_prompt"] = self._system_prompt
        self.recorder["call_count"] += 1
        return self.response_text

    def __deepcopy__(self, memo):
        new = MockChat.__new__(MockChat)
        memo[id(self)] = new
        new._turns = copy.deepcopy(self._turns, memo)
        new._system_prompt = self._system_prompt
        new.response_text = self.response_text
        new.recorder = self.recorder  # shared reference: NOT deep-copied
        return new


def _fit_ols():
    """A small, real fitted statsmodels OLS model (used to exercise the
    actual handler registry, which dispatches on the exact type returned by
    ``.fit()`` -- a ``RegressionResultsWrapper``, not ``OLSResults``)."""
    rng = np.random.default_rng(0)
    x = sm.add_constant(rng.random(20))
    y = 2 + 3 * x[:, 1] + rng.normal(size=20)
    return sm.OLS(y, x).fit()


def _fit_glm():
    """A small, real fitted statsmodels Poisson GLM."""
    rng = np.random.default_rng(0)
    x = sm.add_constant(rng.random(20))
    counts = rng.poisson(5, size=20)
    return sm.GLM(counts, x, family=sm.families.Poisson()).fit()


def test_explain_calls_chat_with_correct_prompts():
    """Tests that explain() calls client.chat() with correctly assembled
    prompts, and does not mutate the caller's client object."""
    # --- Arrange ---
    mock_chat = MockChat("This is a mock explanation.")
    ols_model = _fit_ols()

    # --- Act ---
    result = explain(
        model_object=ols_model,
        client=mock_chat,
        context="A test context for the model.",
        audience="researcher",
    )

    # --- Assert ---
    assert mock_chat.recorder["call_count"] == 1

    system_prompt = mock_chat.recorder["last_system_prompt"]
    user_prompt = mock_chat.recorder["last_user_prompt"]

    assert "Target Audience: Researcher" in system_prompt
    assert "OLS Regression Results" in user_prompt
    assert "A test context for the model." in user_prompt

    assert result["text"] == "This is a mock explanation."
    assert result["model_type"] == "lm"

    # The original client object must remain untouched (no leaked state).
    assert mock_chat.system_prompt is None
    assert mock_chat._turns == []


def test_explain_handles_glm():
    """Tests that the GLM handler is correctly used."""
    # Arrange
    mock_chat = MockChat()
    glm_model = _fit_glm()

    # Act
    result = explain(model_object=glm_model, client=mock_chat)

    # Assert
    assert mock_chat.recorder["call_count"] == 1
    user_prompt = mock_chat.recorder["last_user_prompt"]

    # Check that the user prompt identifies the model as a "glm"
    assert "Explain the following glm model output:" in user_prompt
    assert "Generalized Linear Model (GLM) with Poisson family" in user_prompt
    assert result["model_type"] == "glm"


def test_explain_validates_audience():
    mock_chat = MockChat()
    ols_model = _fit_ols()
    try:
        explain(model_object=ols_model, client=mock_chat, audience="bogus")
        assert False, "expected ValueError"
    except ValueError as e:
        assert "audience" in str(e)

