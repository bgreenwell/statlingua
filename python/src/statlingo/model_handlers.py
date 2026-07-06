# src/statlingo/model_handlers.py

# General workflow:
#
# 1. Add a handler for a new model type in model_handlers.py.
# 2. Add a test for that handler in tests/test_explain.py.
# 3. Run pytest to ensure everything still works.
#
# We can now systematically add support for models from scikit-learn, lifelines
# (for survival analysis), and other popular Python data science libraries.

from __future__ import annotations

from typing import Any, Callable, Optional, Tuple
import io
from contextlib import redirect_stdout


# The registry to hold our model handlers
MODEL_HANDLERS: dict[type, Callable[[Any], Tuple[str, Optional[str], str]]] = {}


def register_handler(model_class: type):
    """A decorator to register a handler for a specific model class.

    Parameters
    ----------
    model_class : type
        The class of the model object to be handled (e.g., OLSResults).
    """

    def decorator(func: Callable[[Any], Tuple[str, Optional[str], str]]):
        """The actual decorator that registers the function."""
        MODEL_HANDLERS[model_class] = func
        return func

    return decorator


def get_handler(model_object: Any) -> Callable[[Any], Tuple[str, Optional[str], str]]:
    """Finds the appropriate handler for a given model object.

    If a specific handler for the object's class is not found, it
    returns the default handler.

    Parameters
    ----------
    model_object : Any
        The statistical model object to be explained.

    Returns
    -------
    Callable[[Any], Tuple[str, Optional[str], str]]
        The handler function to be used for the object.
    """
    # Try exact class match first
    if type(model_object) in MODEL_HANDLERS:
        return MODEL_HANDLERS[type(model_object)]
    # Fallback to subclass check
    for registered_type, handler in MODEL_HANDLERS.items():
        if isinstance(model_object, registered_type):
            return handler
    return handle_default


# Define Handlers --------------------------------------------------------------


def handle_default(model_object: Any) -> Tuple[str, Optional[str], str]:
    """Default handler for unsupported objects.

    Tries to call a `.summary()` method if it exists, otherwise
    falls back to converting the object to a string.

    Parameters
    ----------
    model_object : Any
        The statistical model object.

    Returns
    -------
    tuple[str, Optional[str], str]
        A tuple containing the model name ("default"), no engine identifier
        (``None``), and its string summary.
    """
    summary_text = ""
    if hasattr(model_object, "summary") and callable(model_object.summary):
        summary_text = str(model_object.summary())
    else:
        summary_text = str(model_object)
    return ("default", None, summary_text)


def _format_value(value: Any) -> str:
    """Format numeric values compactly for LLM-facing summaries."""
    try:
        return f"{float(value):.6g}"
    except (TypeError, ValueError):
        return str(value)


def _feature_names(model_object: Any, n_features: int) -> list[str]:
    """Return feature names if the estimator retained them, else fall back
    to positional labels."""
    names = getattr(model_object, "feature_names_in_", None)
    if names is not None:
        return [str(name) for name in names]
    return [f"feature_{i}" for i in range(n_features)]


def _coefficient_lines(
    coefficients: Any, feature_names: list[str], section_label: Optional[str] = None
) -> list[str]:
    """Format coefficient vectors or matrices into readable labeled lines."""
    if hasattr(coefficients, "ndim") and coefficients.ndim > 1:
        lines = []
        for index, row in enumerate(coefficients):
            if section_label is None:
                lines.append(f"Coefficient set {index}:")
            else:
                lines.append(f"{section_label} {index}:")
            lines.extend(_coefficient_lines(row, feature_names))
        return lines

    values = coefficients.tolist() if hasattr(coefficients, "tolist") else coefficients
    if not isinstance(values, (list, tuple)):
        values = [values]
    return [f"  - {name}: {_format_value(value)}" for name, value in zip(feature_names, values)]


# Add support for OLS (Ordinary Least Squares) models
try:
    # NOTE: `sm.OLS(...).fit()` returns a `RegressionResultsWrapper`, not an
    # `OLSResults` directly (statsmodels wraps raw Results objects via a
    # proxying wrapper that does NOT subclass the raw Results class -- see
    # `statsmodels.base.wrapper.ResultsWrapper`). Register against the
    # wrapper class actually returned to callers.
    from statsmodels.regression.linear_model import RegressionResultsWrapper

    @register_handler(RegressionResultsWrapper)
    def handle_lm(
        model_object: RegressionResultsWrapper,
    ) -> Tuple[str, Optional[str], str]:
        """Handler for statsmodels OLS (linear models).

        Parameters
        ----------
        model_object : RegressionResultsWrapper
            The fitted Ordinary Least Squares model object.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name (``"linear_model"``), engine
            (``"statsmodels"``), and its summary.
        """
        return ("linear_model", "statsmodels", str(model_object.summary()))

except ImportError:
    # This allows the package to be imported even if statsmodels is not installed
    pass

# Add support for GLM (Generalized Linear Models)
try:
    from statsmodels.genmod.generalized_linear_model import GLMResultsWrapper

    @register_handler(GLMResultsWrapper)
    def handle_glm(model_object: GLMResultsWrapper) -> Tuple[str, Optional[str], str]:
        """Handler for statsmodels GLM.

        Parameters
        ----------
        model_object : GLMResultsWrapper
            The fitted Generalized Linear Model object.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name
            (``"generalized_linear_model"``), engine (``"statsmodels"``), and
            its summary.
        """
        family_name = model_object.model.family.__class__.__name__
        link_name = model_object.model.family.link.__class__.__name__
        model_description = f"{family_name} generalized linear model with {link_name} link"
        return (
            "generalized_linear_model",
            "statsmodels",
            model_description + "\n\n" + str(model_object.summary()),
        )

except ImportError:
    pass

# Add support for MixedLM (Linear Mixed-Effects Models)
try:
    from statsmodels.regression.mixed_linear_model import MixedLMResultsWrapper

    @register_handler(MixedLMResultsWrapper)
    def handle_mixedlm(model_object: MixedLMResultsWrapper) -> Tuple[str, Optional[str], str]:
        """Handler for statsmodels MixedLM.

        Parameters
        ----------
        model_object : MixedLMResultsWrapper
            The fitted mixed linear model object.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name (``"linear_mixed_model_nlme"``),
            engine (``"statsmodels"``), and its summary.
        """
        return ("linear_mixed_model_nlme", "statsmodels", str(model_object.summary()))

except ImportError:
    pass

# Add support for ARIMA/SARIMAX time series models
try:
    from statsmodels.tsa.arima.model import ARIMAResultsWrapper
    from statsmodels.tsa.statespace.sarimax import SARIMAXResultsWrapper

    @register_handler(ARIMAResultsWrapper)
    @register_handler(SARIMAXResultsWrapper)
    def handle_arima(model_object: Any) -> Tuple[str, Optional[str], str]:
        """Handler for statsmodels ARIMA/SARIMAX time series models.

        Parameters
        ----------
        model_object : Any
            The fitted time series model object.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name (``"arima_time_series"``),
            engine (``"statsmodels"``), and its summary.
        """
        return ("arima_time_series", "statsmodels", str(model_object.summary()))

except ImportError:
    pass

# Add support for statsmodels survival analysis (PHReg)
try:
    from statsmodels.duration.hazard_regression import PHRegResults

    @register_handler(PHRegResults)
    def handle_phreg(model_object: PHRegResults) -> Tuple[str, Optional[str], str]:
        """Handler for statsmodels PHReg.

        Parameters
        ----------
        model_object : PHRegResults
            The fitted PHReg model object.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name (``"cox_proportional_hazards"``),
            engine (``"statsmodels"``), and its summary.
        """
        return ("cox_proportional_hazards", "statsmodels", str(model_object.summary()))

except ImportError:
    pass

# Add support for lifelines survival analysis models
try:
    from lifelines import CoxPHFitter, WeibullAFTFitter, LogNormalAFTFitter, LogLogisticAFTFitter

    @register_handler(CoxPHFitter)
    def handle_lifelines_cox(model_object: CoxPHFitter) -> Tuple[str, Optional[str], str]:
        """Handler for lifelines CoxPHFitter.

        Parameters
        ----------
        model_object : CoxPHFitter
            The fitted Cox proportional hazards model.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name (``"cox_proportional_hazards"``),
            engine (``"lifelines"``), and its summary.
        """
        f = io.StringIO()
        with redirect_stdout(f):
            model_object.print_summary()
        summary_text = f.getvalue()
        if not summary_text.strip():
            summary_text = str(model_object.summary)
        return ("cox_proportional_hazards", "lifelines", summary_text)

    @register_handler(WeibullAFTFitter)
    @register_handler(LogNormalAFTFitter)
    @register_handler(LogLogisticAFTFitter)
    def handle_lifelines_aft(model_object: Any) -> Tuple[str, Optional[str], str]:
        """Handler for lifelines parametric AFT models.

        Parameters
        ----------
        model_object : Any
            The fitted parametric AFT model.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name (``"survival_regression"``),
            engine (``"lifelines"``), and its summary.
        """
        f = io.StringIO()
        with redirect_stdout(f):
            model_object.print_summary()
        summary_text = f.getvalue()
        if not summary_text.strip():
            summary_text = str(model_object.summary)
        return ("survival_regression", "lifelines", summary_text)

except ImportError:
    pass

# Add support for pygam Generalized Additive Models (GAM)
try:
    from pygam import GAM

    @register_handler(GAM)
    def handle_pygam(model_object: GAM) -> Tuple[str, Optional[str], str]:
        """Handler for pygam GAM models.

        Parameters
        ----------
        model_object : GAM
            The fitted GAM model.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name (``"generalized_additive_model"``),
            engine (``"pygam"``), and its summary.
        """
        f = io.StringIO()
        with redirect_stdout(f):
            try:
                model_object.summary()
            except Exception as e:
                f.write(f"Error generating summary: {e}")
        summary_text = f.getvalue()
        if not summary_text.strip():
            summary_text = f"Generalized Additive Model (GAM) using pygam\n{str(model_object)}"
        return ("generalized_additive_model", "pygam", summary_text)

except ImportError:
    pass

# Add support for scikit-learn linear models
try:
    from sklearn.linear_model import LinearRegression, LogisticRegression

    @register_handler(LinearRegression)
    def handle_sklearn_lm(
        model_object: LinearRegression,
    ) -> Tuple[str, Optional[str], str]:
        """Handler for scikit-learn ``LinearRegression`` estimators.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name (``"linear_model"``), engine
            (``"sklearn"``), and a synthesized summary.
        """
        coefficients = model_object.coef_
        n_features = getattr(
            model_object,
            "n_features_in_",
            coefficients.shape[-1] if hasattr(coefficients, "shape") else len(coefficients),
        )
        feature_names = _feature_names(model_object, n_features)

        lines = [
            "Model type: scikit-learn LinearRegression",
            f"Number of features: {n_features}",
            f"Intercept: {_format_value(model_object.intercept_)}",
            "Coefficients:",
            *_coefficient_lines(coefficients, feature_names),
        ]
        # scikit-learn estimators do not retain training X/y after `.fit()`,
        # so goodness-of-fit metrics like R^2 cannot be recovered later from
        # the fitted object alone unless the caller provides the data again.
        lines.append(
            "R-squared: not available from the fitted estimator alone "
            "(scikit-learn does not store the training data)."
        )
        return ("linear_model", "sklearn", "\n".join(lines))

    @register_handler(LogisticRegression)
    def handle_sklearn_glm(
        model_object: LogisticRegression,
    ) -> Tuple[str, Optional[str], str]:
        """Handler for scikit-learn ``LogisticRegression`` estimators.

        Returns
        -------
        tuple[str, Optional[str], str]
            A tuple containing the model name
            (``"generalized_linear_model"``), engine (``"sklearn"``), and a
            synthesized summary.
        """
        coefficients = model_object.coef_
        n_features = getattr(
            model_object,
            "n_features_in_",
            coefficients.shape[-1] if hasattr(coefficients, "shape") else len(coefficients),
        )
        feature_names = _feature_names(model_object, n_features)
        class_labels = [str(label) for label in getattr(model_object, "classes_", [])]

        lines = [
            "Model type: scikit-learn LogisticRegression",
            f"Number of classes: {len(class_labels)}",
            f"Classes: {', '.join(class_labels)}",
            f"Number of features: {n_features}",
        ]

        if len(class_labels) == 2 and hasattr(coefficients, "shape") and coefficients.shape[0] == 1:
            positive_class = class_labels[1]
            lines.append(f"Intercept for positive class ({positive_class}): {_format_value(model_object.intercept_[0])}")
            lines.append(f"Coefficients for positive class ({positive_class}):")
            lines.extend(_coefficient_lines(coefficients[0], feature_names))
        else:
            # Multiclass logistic regression stores one coefficient vector per
            # class (or per decision function row), so summarize each row with
            # the aligned class label when available.
            intercepts = (
                model_object.intercept_.tolist()
                if hasattr(model_object.intercept_, "tolist")
                else model_object.intercept_
            )
            for index, row in enumerate(coefficients):
                class_label = class_labels[index] if index < len(class_labels) else index
                intercept_value = intercepts[index] if isinstance(intercepts, list) else intercepts
                lines.append(f"Intercept for class ({class_label}): {_format_value(intercept_value)}")
                lines.append(f"Coefficients for class ({class_label}):")
                lines.extend(_coefficient_lines(row, feature_names))

        return ("generalized_linear_model", "sklearn", "\n".join(lines))

except ImportError:
    pass
