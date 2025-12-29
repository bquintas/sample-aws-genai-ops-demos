"""AWS Chaos Engineering MCP Server.

This package provides an MCP server for AWS FIS (Fault Injection Simulator) operations,
enabling natural language generation of chaos engineering experiment templates.
"""

__version__ = "0.1.0"
__author__ = "AWS GenAI Ops Demo Library"
__email__ = "genai-ops@amazon.com"

from .server import mcp

__all__ = ["mcp"]