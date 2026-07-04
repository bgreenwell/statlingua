"""Assemble LLM system/user prompts from the canonical ``prompts/`` data.

Mirrors the R package's approach (see ``r/R/utils.R``): short audience,
verbosity, and style instruction strings live in ``prompts/config.yaml``;
longer, model-specific instructions live as markdown files under
``prompts/models/<name>/``. Both are interpolated into
``prompts/system_prompt_template.md``.

This module intentionally lives outside the ``statlingo/prompts/`` data
directory (which is regenerated wholesale by ``scripts/sync_prompts.py`` and
should contain only data files, not code).
"""

from __future__ import annotations

import importlib.resources
import re
from functools import lru_cache
from typing import Optional

import yaml

_PLACEHOLDER_RE = re.compile(r"\{\{\s*(\w+)\s*\}\}")
_ENGINE_NOTE_FILES = {
    ("linear_model", "statsmodels"): "statsmodels-ols.md",
    ("linear_model", "sklearn"): "sklearn-linear.md",
    ("generalized_linear_model", "statsmodels"): "statsmodels-glm.md",
    ("generalized_linear_model", "sklearn"): "sklearn-logistic.md",
}


def _read_prompt_file(*path_parts: str) -> str:
    """Read a file from the installed ``statlingo/prompts`` data directory.

    Returns an empty string if the file doesn't exist, mirroring the R
    implementation's graceful-fallback behavior.
    """
    try:
        return (
            importlib.resources.files("statlingo")
            .joinpath("prompts", *path_parts)
            .read_text(encoding="utf-8")
        )
    except (FileNotFoundError, NotADirectoryError):
        return ""


@lru_cache(maxsize=1)
def _prompt_config() -> dict:
    """Read and cache ``prompts/config.yaml`` (audience/verbosity/style)."""
    raw = _read_prompt_file("config.yaml")
    return yaml.safe_load(raw) or {}


def _interpolate(template: str, **kwargs: str) -> str:
    """Lightweight ``{{ placeholder }}`` interpolation (mirrors ellmer's
    ``interpolate()``, which wraps glue with ``{{ }}`` delimiters instead of
    ``{ }`` so prompts containing JSON/LaTeX braces don't need escaping).
    """

    def _replace(match: "re.Match[str]") -> str:
        key = match.group(1)
        if key not in kwargs:
            raise KeyError(f"Missing template variable: {key!r}")
        return str(kwargs[key])

    return _PLACEHOLDER_RE.sub(_replace, template)


def _has_model_instructions(model_name: str) -> bool:
    return bool(_read_prompt_file("models", model_name, "instructions.md"))


def _read_engine_notes(model_name: str, engine: Optional[str]) -> str:
    """Read optional engine-specific notes for a model/engine pair."""
    if engine is None:
        return ""

    filename = _ENGINE_NOTE_FILES.get((model_name, engine))
    if not filename:
        return ""

    return _read_prompt_file("models", model_name, "engines", filename).strip()


def assemble_system_prompt(
    model_name: str,
    audience: str,
    verbosity: str,
    style: str,
    engine: Optional[str] = None,
) -> str:
    """Assemble the full system prompt for a model type/audience/verbosity/style.

    Parameters
    ----------
    model_name : str
        Internal model type name (e.g. ``"linear_model"``,
        ``"generalized_linear_model"``), corresponding to a directory in
        ``prompts/models/``. Falls back to ``"default"`` if no such directory
        (or no ``instructions.md``) exists.
    audience : str
        One of the keys in ``config.yaml``'s ``audience`` map.
    verbosity : str
        One of the keys in ``config.yaml``'s ``verbosity`` map.
    style : str
        One of the keys in ``config.yaml``'s ``style`` map.
    engine : str, optional
        Optional engine/library identifier used to inject engine-specific
        output-format notes when available.

    Returns
    -------
    str
        The fully assembled system prompt.
    """
    if not _has_model_instructions(model_name):
        model_name = "default"

    config = _prompt_config()
    engine_notes = _read_engine_notes(model_name, engine)
    engine_section = (
        f"## Output Format Notes\n\n{engine_notes}\n" if engine_notes else ""
    )

    role_base = _read_prompt_file("common", "role_base.md").strip()
    role_specific = _read_prompt_file(
        "models", model_name, "role_specific.md"
    ).strip()
    role_instruction = "\n\n".join(p for p in (role_base, role_specific) if p)

    template = _read_prompt_file("system_prompt_template.md")

    def _title_case(value: str) -> str:
        """Capitalize only the first character, mirroring R's
        ``tools::toTitleCase()`` behavior for single "word" inputs like
        ``"domain_expert"`` (which it renders as ``"Domain_expert"``, not
        ``"Domain Expert"``) -- kept in sync so the assembled system prompt
        text matches exactly between the R and Python packages.
        """
        return value[:1].upper() + value[1:]

    return _interpolate(
        template,
        role_instruction=role_instruction,
        audience_title=_title_case(audience),
        audience_instruction=config["audience"][audience],
        verbosity_title=_title_case(verbosity),
        verbosity_instruction=config["verbosity"][verbosity],
        style_title=_title_case(style),
        style_instruction=config["style"][style],
        model_instructions=_read_prompt_file(
            "models", model_name, "instructions.md"
        ).strip(),
        engine_section=engine_section,
        caution_instruction=_read_prompt_file("common", "caution.md").strip(),
    ).strip()


def build_user_prompt(
    model_description: str, output: str, context: Optional[str] = None
) -> str:
    """Build the user prompt containing the model's captured summary output."""
    prompt = f"Explain the following {model_description} output:\n\n---\n\n{output}"
    if context and context.strip():
        prompt += f"\n\n---\n\n## Additional context to consider\n\n{context.strip()}"
    return prompt


_FENCE_RE = re.compile(r"^`{3,}([a-zA-Z0-9_-]*)?\s*\n?(.*?)\n?\s*`{3,}$", re.DOTALL)


def remove_fences(text: Optional[str]) -> Optional[str]:
    """Strip a single pair of surrounding Markdown code fences, if present.

    Mirrors R's ``.remove_fences()``: LLMs sometimes wrap their entire
    response in ```` ```lang ... ``` ```` even when told not to.
    """
    if not text:
        return text
    match = _FENCE_RE.match(text.strip())
    if match:
        return match.group(2).strip()
    return text
