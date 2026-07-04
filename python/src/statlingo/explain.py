"""Core ``explain()`` entry point: turn a fitted model into an LLM explanation."""

from __future__ import annotations

import copy
from typing import Any, Optional

from ._prompting import assemble_system_prompt, build_user_prompt, remove_fences
from .model_handlers import get_handler

_VALID_AUDIENCES = (
    "novice",
    "student",
    "researcher",
    "manager",
    "domain_expert",
)
_VALID_VERBOSITY = ("brief", "moderate", "detailed")
_VALID_STYLES = ("markdown", "html", "json", "text", "latex")


def _validate_choice(name: str, value: str, choices: tuple) -> str:
    if value not in choices:
        raise ValueError(f"`{name}` must be one of {choices!r}, got {value!r}.")
    return value


def _chat_once(client: Any, system_prompt: str, user_prompt: str) -> str:
    """Send a single system+user prompt turn without mutating the caller's
    ``chatlas.Chat`` object.

    ``chatlas.Chat`` has no ``clone()`` method; ``copy.deepcopy()`` is
    chatlas's own documented/tested pattern for forking a ``Chat`` (see
    ``Chat.to_solver()`` in chatlas's source, and
    ``tests/test_chat.py::test_deepcopy_chat``). This mirrors the R/ellmer
    implementation's ``client$clone()`` + ``set_turns(list())`` +
    ``set_system_prompt()`` pattern exactly.
    """
    temp_chat = copy.deepcopy(client)
    temp_chat.set_turns([])  # clear any existing history (system prompt aside)
    temp_chat.system_prompt = system_prompt
    response = temp_chat.chat(user_prompt, echo="none", stream=False)
    return str(response)


def explain(
    model_object: Any,
    client: Any,
    context: Optional[str] = None,
    language: Optional[str] = None,
    audience: str = "novice",
    verbosity: str = "moderate",
    style: str = "markdown",
) -> dict:
    """Explain a statistical model's output using an LLM.

    Parameters
    ----------
    model_object : Any
        A fitted statistical model object from a supported library (e.g., a
        results object from ``statsmodels``).
    client : chatlas.Chat
        A chatlas ``Chat`` client (e.g. from ``chatlas.ChatOpenAI()`` or
        ``chatlas.ChatAnthropic()``). Never mutated by this function.
    context : str, optional
        Additional context about the data or research question to provide
        to the LLM.
    language : str, optional
        The language the explanation should be written in (e.g. "Spanish",
        "French", "Mandarin Chinese"). If None (the default), no language
        constraint is added and the LLM will typically respond in the same
        language as the input/context or its default language.
    audience : str, optional
        The target audience: one of "novice" (default), "student",
        "researcher", "manager", or "domain_expert".
    verbosity : str, optional
        The desired level of detail: one of "brief", "moderate" (default),
        or "detailed".
    style : str, optional
        The output format style: one of "markdown" (default), "html",
        "json", "text", or "latex".

    Returns
    -------
    dict
        A dictionary with keys: ``text``, ``model_type``, ``audience``,
        ``verbosity``, ``style``.
    """
    audience = _validate_choice("audience", audience, _VALID_AUDIENCES)
    verbosity = _validate_choice("verbosity", verbosity, _VALID_VERBOSITY)
    style = _validate_choice("style", style, _VALID_STYLES)

    handler = get_handler(model_object)
    model_name, engine, summary_text = handler(model_object)

    system_prompt = assemble_system_prompt(
        model_name, audience, verbosity, style, engine=engine, language=language
    )
    user_prompt = build_user_prompt(
        model_description=f"{model_name} model", output=summary_text, context=context
    )

    explanation_text = remove_fences(_chat_once(client, system_prompt, user_prompt))

    return {
        "text": explanation_text,
        "model_type": model_name,
        "audience": audience,
        "verbosity": verbosity,
        "style": style,
    }
