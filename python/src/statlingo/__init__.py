# src/statlingo/__init__.py

# Make the main functions available at the top level of the package
from .explain import explain, suggest_code

__all__ = ["explain", "suggest_code"]
__version__ = "0.1.0"
