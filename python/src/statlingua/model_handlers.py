# src/statlingua/model_handlers.py

# General workflow:
#
# 1. Add a handler for a new model type in model_handlers.py.
# 2. Add a test for that handler in tests/test_explain.py.
# 3. Run pytest to ensure everything still works.
#
# We can now systematically add support for models from scikit-learn, lifelines
# (for survival analysis), and other popular Python data science libraries.

from typing import Any, Callable, Tuple

# The registry to hold our model handlers
MODEL_HANDLERS: dict[type, Callable[[Any], Tuple[str, str]]] = {}


def register_handler(model_class: type):
    """A decorator to register a handler for a specific model class.

    Parameters
    ----------
    model_class : type
        The class of the model object to be handled (e.g., OLSResults).
    """

    def decorator(func: Callable[[Any], Tuple[str, str]]):
        """The actual decorator that registers the function."""
        MODEL_HANDLERS[model_class] = func
        return func

    return decorator


def get_handler(model_object: Any) -> Callable[[Any], Tuple[str, str]]:
    """Finds the appropriate handler for a given model object.

    If a specific handler for the object's class is not found, it
    returns the default handler.

    Parameters
    ----------
    model_object : Any
        The statistical model object to be explained.

    Returns
    -------
    Callable[[Any], Tuple[str, str]]
        The handler function to be used for the object.
    """
    return MODEL_HANDLERS.get(type(model_object), handle_default)


# Define Handlers --------------------------------------------------------------


def handle_default(model_object: Any) -> Tuple[str, str]:
    """Default handler for unsupported objects.

    Tries to call a `.summary()` method if it exists, otherwise
    falls back to converting the object to a string.

    Parameters
    ----------
    model_object : Any
        The statistical model object.

    Returns
    -------
    tuple[str, str]
        A tuple containing the model name ("default") and its string summary.
    """
    summary_text = ""
    if hasattr(model_object, "summary") and callable(model_object.summary):
        summary_text = str(model_object.summary())
    else:
        summary_text = str(model_object)
    return ("default", summary_text)


# Add support for OLS (Ordinary Least Squares) models
try:
    # NOTE: `sm.OLS(...).fit()` returns a `RegressionResultsWrapper`, not an
    # `OLSResults` directly (statsmodels wraps raw Results objects via a
    # proxying wrapper that does NOT subclass the raw Results class -- see
    # `statsmodels.base.wrapper.ResultsWrapper`). Register against the
    # wrapper class actually returned to callers.
    from statsmodels.regression.linear_model import RegressionResultsWrapper

    @register_handler(RegressionResultsWrapper)
    def handle_lm(model_object: RegressionResultsWrapper) -> Tuple[str, str]:
        """Handler for statsmodels OLS (linear models).

        Parameters
        ----------
        model_object : RegressionResultsWrapper
            The fitted Ordinary Least Squares model object.

        Returns
        -------
        tuple[str, str]
            A tuple containing the model name ("lm") and its summary.
        """
        return ("lm", str(model_object.summary()))

except ImportError:
    # This allows the package to be imported even if statsmodels is not installed
    pass

# Add support for GLM (Generalized Linear Models)
try:
    from statsmodels.genmod.generalized_linear_model import GLMResultsWrapper

    @register_handler(GLMResultsWrapper)
    def handle_glm(model_object: GLMResultsWrapper) -> Tuple[str, str]:
        """Handler for statsmodels GLM.

        Parameters
        ----------
        model_object : GLMResultsWrapper
            The fitted Generalized Linear Model object.

        Returns
        -------
        tuple[str, str]
            A tuple containing the model name ("glm") and its summary.
        """
        # We can extract more details like the family for a better description
        family_name = model_object.model.family.__class__.__name__
        model_description = f"Generalized Linear Model (GLM) with {family_name} family"
        return ("glm", model_description + "\n\n" + str(model_object.summary()))

except ImportError:
    pass
