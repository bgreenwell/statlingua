# src/statlingo/__init__.py

# Make the main functions available at the top level of the package
from .explain import explain
from .diagnostic import diagnose, diagnose_agent

__all__ = ["explain", "diagnose", "diagnose_agent"]
__version__ = "0.1.0"
