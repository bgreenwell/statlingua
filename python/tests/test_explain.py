# tests/test_explain.py

import copy

import numpy as np
import pytest
import statsmodels.api as sm

from statlingo._prompting import assemble_system_prompt
from statlingo.explain import explain


class MockChat:
    """A minimal test double matching chatlas.Chat's public surface used by
    ``explain()``: ``set_turns()``, a settable ``system_prompt`` property,
    and ``chat()``.

    ``explain()`` calls ``copy.deepcopy(client)`` before use (chatlas's own
    documented pattern for forking a Chat without mutating the caller's
    object -- see ``_chat_once()`` in ``statlingo.explain``), so any state
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


def _fit_sklearn_linear_regression():
    """A small, real fitted scikit-learn linear regression model."""
    sklearn = pytest.importorskip("sklearn")
    assert sklearn is not None  # appease linters about the importorskip result
    from sklearn.linear_model import LinearRegression

    x = np.array(
        [
            [0.0, 0.0],
            [1.0, 0.0],
            [0.0, 1.0],
            [2.0, 1.0],
            [1.0, 2.0],
            [3.0, 1.0],
        ]
    )
    y = 1.0 + 2.0 * x[:, 0] - 1.0 * x[:, 1]
    return LinearRegression().fit(x, y)


def _fit_sklearn_logistic_regression():
    """A small, real fitted scikit-learn logistic regression model."""
    sklearn = pytest.importorskip("sklearn")
    assert sklearn is not None
    from sklearn.linear_model import LogisticRegression

    x = np.array(
        [
            [-2.0, -1.0],
            [-1.0, -1.0],
            [-1.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [2.0, 1.0],
        ]
    )
    y = np.array([0, 0, 0, 1, 1, 1])
    return LogisticRegression(random_state=0, max_iter=200).fit(x, y)


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
    assert "This output was produced by Python's `statsmodels` library" in system_prompt
    assert "Coefficients table" in system_prompt
    assert "OLS Regression Results" in user_prompt
    assert "A test context for the model." in user_prompt

    assert result["text"].startswith("This is a mock explanation.")
    assert result["model_type"] == "linear_model"

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

    system_prompt = mock_chat.recorder["last_system_prompt"]

    # Check that the user prompt identifies the model with the semantic key.
    assert (
        "Explain the following generalized_linear_model model output:"
        in user_prompt
    )
    assert "Poisson generalized linear model with Log link" in user_prompt
    assert "Link Function" in system_prompt
    assert "confidence intervals uniquely available in this output" in system_prompt
    assert result["model_type"] == "generalized_linear_model"


def test_explain_handles_sklearn_linear_regression():
    """Tests that the scikit-learn linear regression handler is used."""
    mock_chat = MockChat()
    model = _fit_sklearn_linear_regression()

    result = explain(model_object=model, client=mock_chat)

    assert mock_chat.recorder["call_count"] == 1
    user_prompt = mock_chat.recorder["last_user_prompt"]

    system_prompt = mock_chat.recorder["last_system_prompt"]

    assert "Explain the following linear_model model output:" in user_prompt
    assert "Model type: scikit-learn LinearRegression" in user_prompt
    assert "Number of features: 2" in user_prompt
    assert "Intercept: 1" in user_prompt
    assert "feature_0: 2" in user_prompt
    assert "feature_1: -1" in user_prompt
    assert "R-squared: not available from the fitted estimator alone" in user_prompt
    assert "scikit-learn's `LinearRegression` has no built-in text summary" in system_prompt
    assert "Do not invent, estimate, or imply the presence" in system_prompt
    assert result["model_type"] == "linear_model"


def test_explain_handles_sklearn_logistic_regression():
    """Tests that the scikit-learn logistic regression handler is used."""
    mock_chat = MockChat()
    model = _fit_sklearn_logistic_regression()

    result = explain(model_object=model, client=mock_chat)

    assert mock_chat.recorder["call_count"] == 1
    user_prompt = mock_chat.recorder["last_user_prompt"]

    system_prompt = mock_chat.recorder["last_system_prompt"]

    assert (
        "Explain the following generalized_linear_model model output:"
        in user_prompt
    )
    assert "Model type: scikit-learn LogisticRegression" in user_prompt
    assert "Number of classes: 2" in user_prompt
    assert "Classes: 0, 1" in user_prompt
    assert "Number of features: 2" in user_prompt
    assert "Coefficients for positive class (1):" in user_prompt
    assert "feature_0:" in user_prompt
    assert "feature_1:" in user_prompt
    assert "scikit-learn's `LogisticRegression` has no built-in text summary" in system_prompt
    assert "applies L2 regularization" in system_prompt
    assert result["model_type"] == "generalized_linear_model"


def test_assemble_system_prompt_includes_language_section_when_requested():
    prompt = assemble_system_prompt(
        "linear_model", "novice", "brief", "markdown", language="Spanish"
    )

    assert "## Response Language" in prompt
    assert "Respond only in Spanish" in prompt


def test_assemble_system_prompt_omits_language_section_by_default():
    prompt = assemble_system_prompt("linear_model", "novice", "brief", "markdown")

    assert "## Response Language" not in prompt


def test_explain_threads_language_into_system_prompt():
    mock_chat = MockChat()
    ols_model = _fit_ols()

    explain(model_object=ols_model, client=mock_chat, language="French")

    assert "Respond only in French" in mock_chat.recorder["last_system_prompt"]


def test_explain_validates_audience():
    mock_chat = MockChat()
    ols_model = _fit_ols()
    try:
        explain(model_object=ols_model, client=mock_chat, audience="bogus")
        assert False, "expected ValueError"
    except ValueError as e:
        assert "audience" in str(e)


def test_suggest_code():
    from statlingo import suggest_code

    explanation = {
        "text": "Explanation text",
        "model_type": "linear_model",
        "audience": "student",
    }
    suggestions = suggest_code(explanation)
    assert "Suggested Python Coding Diagnostics" in suggestions
    assert "sns.residplot" in suggestions
    assert "durbin_watson" in suggestions


def _fit_glm_binomial():
    rng = np.random.default_rng(0)
    x = sm.add_constant(rng.random((20, 1)))
    y = rng.binomial(1, 0.5, size=20)
    return sm.GLM(y, x, family=sm.families.Binomial()).fit()


def _fit_glm_gamma():
    rng = np.random.default_rng(0)
    x = sm.add_constant(rng.random((20, 1)) + 0.1)
    y = rng.exponential(scale=1.0, size=20) + 0.1
    return sm.GLM(y, x, family=sm.families.Gamma()).fit()


def _fit_glm_negative_binomial():
    rng = np.random.default_rng(0)
    x = sm.add_constant(rng.random((20, 1)))
    y = rng.poisson(5, size=20)
    return sm.GLM(y, x, family=sm.families.NegativeBinomial()).fit()


def _fit_mixedlm():
    rng = np.random.default_rng(0)
    groups = np.repeat(np.arange(5), 4)
    x = rng.normal(size=20)
    y = 2 + 1.5 * x + groups + rng.normal(size=20)
    return sm.MixedLM(y, sm.add_constant(x), groups=groups).fit()


def _fit_arima():
    rng = np.random.default_rng(0)
    y = np.cumsum(rng.normal(size=30))
    return sm.tsa.arima.ARIMA(y, order=(1, 0, 0)).fit()


def _fit_phreg():
    from statsmodels.duration.hazard_regression import PHReg
    rng = np.random.default_rng(0)
    time = rng.exponential(10, size=20)
    status = rng.binomial(1, 0.8, size=20)
    x = rng.normal(size=20)
    return PHReg(time, x, status=status).fit()


def _fit_lifelines_cox():
    lifelines = pytest.importorskip("lifelines")
    import pandas as pd
    rng = np.random.default_rng(0)
    df = pd.DataFrame({
        "time": rng.exponential(10, size=20),
        "status": rng.binomial(1, 0.8, size=20),
        "x": rng.normal(size=20)
    })
    cph = lifelines.CoxPHFitter()
    cph.fit(df, duration_col="time", event_col="status")
    return cph


def _fit_lifelines_weibull_aft():
    lifelines = pytest.importorskip("lifelines")
    import pandas as pd
    rng = np.random.default_rng(0)
    df = pd.DataFrame({
        "time": rng.exponential(10, size=20) + 0.1,
        "status": rng.binomial(1, 0.8, size=20),
        "x": rng.normal(size=20)
    })
    aft = lifelines.WeibullAFTFitter()
    aft.fit(df, duration_col="time", event_col="status")
    return aft


def _fit_pygam_gam():
    pygam = pytest.importorskip("pygam")
    rng = np.random.default_rng(0)
    x = rng.normal(size=(20, 1))
    y = 2 * x[:, 0] + rng.normal(size=20)
    gam = pygam.LinearGAM().fit(x, y)
    return gam


def test_explain_handles_glm_families():
    mock_chat = MockChat()
    for fit_func in [_fit_glm_binomial, _fit_glm_gamma, _fit_glm_negative_binomial]:
        model = fit_func()
        result = explain(model_object=model, client=mock_chat)
        assert result["model_type"] == "generalized_linear_model"
        user_prompt = mock_chat.recorder["last_user_prompt"]
        assert "generalized_linear_model" in user_prompt


def test_explain_handles_mixedlm():
    mock_chat = MockChat()
    model = _fit_mixedlm()
    result = explain(model_object=model, client=mock_chat)
    assert result["model_type"] == "linear_mixed_model_nlme"
    user_prompt = mock_chat.recorder["last_user_prompt"]
    assert "linear_mixed_model_nlme" in user_prompt


def test_explain_handles_arima():
    mock_chat = MockChat()
    model = _fit_arima()
    result = explain(model_object=model, client=mock_chat)
    assert result["model_type"] == "arima_time_series"
    user_prompt = mock_chat.recorder["last_user_prompt"]
    assert "arima_time_series" in user_prompt


def test_explain_handles_phreg():
    mock_chat = MockChat()
    model = _fit_phreg()
    result = explain(model_object=model, client=mock_chat)
    assert result["model_type"] == "cox_proportional_hazards"
    user_prompt = mock_chat.recorder["last_user_prompt"]
    assert "cox_proportional_hazards" in user_prompt


def test_explain_handles_lifelines():
    mock_chat = MockChat()
    
    # CoxPHFitter
    cox = _fit_lifelines_cox()
    result = explain(model_object=cox, client=mock_chat)
    assert result["model_type"] == "cox_proportional_hazards"
    
    # WeibullAFTFitter
    weibull = _fit_lifelines_weibull_aft()
    result = explain(model_object=weibull, client=mock_chat)
    assert result["model_type"] == "survival_regression"


def test_explain_handles_pygam():
    mock_chat = MockChat()
    gam = _fit_pygam_gam()
    result = explain(model_object=gam, client=mock_chat)
    assert result["model_type"] == "generalized_additive_model"


def test_explain_handles_custom_prompt_dir(tmp_path):
    mock_chat = MockChat()
    ols_model = _fit_ols()

    # 1. Create a custom prompts directory structure
    custom_dir = tmp_path / "custom_prompts"
    custom_dir.mkdir()
    
    # Create common folder
    common_dir = custom_dir / "common"
    common_dir.mkdir()
    (common_dir / "role_base.md").write_text("CUSTOM BASE ROLE INSTRUCTION", encoding="utf-8")
    (common_dir / "caution.md").write_text("CUSTOM CAUTION INSTRUCTION", encoding="utf-8")
    
    # Create system_prompt_template.md
    (custom_dir / "system_prompt_template.md").write_text(
        "Template: {{ role_instruction }} | {{ caution_instruction }}", encoding="utf-8"
    )

    # 2. Call explain with prompt_dir
    explain(
        model_object=ols_model,
        client=mock_chat,
        prompt_dir=str(custom_dir)
    )

    system_prompt = mock_chat.recorder["last_system_prompt"]
    assert "CUSTOM BASE ROLE INSTRUCTION" in system_prompt
    assert "CUSTOM CAUTION INSTRUCTION" in system_prompt



