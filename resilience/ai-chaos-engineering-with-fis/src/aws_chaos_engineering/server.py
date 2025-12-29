"""MCP server implementation for AWS Chaos Engineering.

This module implements the FastMCP v2 server with tools for FIS data caching,
validation, and template generation support.
"""

from typing import Dict, Any, Optional
import json
import logging

from fastmcp import FastMCP
from pydantic import BaseModel, Field

from .fis_cache import FISCache
from .validators import FISTemplateValidator
from .prompt_templates import generate_system_prompt

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastMCP app
mcp = FastMCP("AWS Chaos Engineering")

# Initialize components
fis_cache = FISCache()
validator = FISTemplateValidator()


class FISActionsResponse(BaseModel):
    """Response model for FIS actions data."""
    
    fis_actions: list[Dict[str, Any]] = Field(description="List of available FIS actions")
    resource_types: list[Dict[str, Any]] = Field(description="List of available resource types")
    last_updated: Optional[str] = Field(description="Timestamp of last cache update")
    region: str = Field(description="AWS region for the data")
    cache_status: str = Field(description="Status of the cache (fresh, stale, empty)")
    instruction: Optional[str] = Field(description="Instruction for agent if cache is stale")


class ValidationResponse(BaseModel):
    """Response model for template validation."""
    
    valid: bool = Field(description="Whether the template is valid")
    errors: list[str] = Field(description="List of validation errors")
    warnings: list[str] = Field(description="List of validation warnings")
    invalid_actions: list[str] = Field(description="List of invalid action IDs")
    invalid_resource_types: list[str] = Field(description="List of invalid resource types")
    validation_timestamp: str = Field(description="Timestamp of validation")


class SystemPromptResponse(BaseModel):
    """Response model for system prompt generation."""
    
    success: bool = Field(description="Whether the prompt generation was successful")
    system_prompt: str = Field(description="Generated system prompt with current FIS data")
    message: str = Field(description="Status message or error description")
    fis_actions_count: int = Field(description="Number of FIS actions included")
    resource_types_count: int = Field(description="Number of resource types included")


class CacheUpdateResponse(BaseModel):
    """Response model for cache updates."""
    
    success: bool = Field(description="Whether the cache update was successful")
    message: str = Field(description="Status message")
    last_updated: Optional[str] = Field(description="Timestamp of cache update")
    region: str = Field(description="AWS region for the updated data")


@mcp.tool
def get_valid_fis_actions(region: str = "us-east-1") -> FISActionsResponse:
    """Returns cached AWS FIS actions and resource types for agent system prompts.
    
    If cache is stale (older than 24 hours), returns instruction for agent to 
    refresh via AWS MCP server first.
    
    Args:
        region: AWS region to get FIS data for (default: us-east-1)
        
    Returns:
        FISActionsResponse with cached data or refresh instructions
    """
    try:
        logger.info(f"Getting FIS actions for region: {region}")
        
        # Get cached data and status
        cached_data = fis_cache.get_cached_data(region)
        cache_status = fis_cache.get_cache_status(region)
        
        if cache_status == "stale":
            return FISActionsResponse(
                fis_actions=[],
                resource_types=[],
                last_updated=cached_data.get("last_updated") if cached_data else None,
                region=region,
                cache_status=cache_status,
                instruction="Cache is stale (older than 24 hours). Please refresh using AWS MCP server: call describe_fis_actions and describe_fis_experiment_templates, then use refresh_valid_fis_actions_cache with the fresh data."
            )
        
        if cache_status == "empty":
            return FISActionsResponse(
                fis_actions=[],
                resource_types=[],
                last_updated=None,
                region=region,
                cache_status=cache_status,
                instruction="No cached data available. Please fetch FIS data using AWS MCP server: call describe_fis_actions and describe_fis_experiment_templates, then use refresh_valid_fis_actions_cache with the data."
            )
        
        # Return fresh cached data
        return FISActionsResponse(
            fis_actions=cached_data.get("fis_actions", []),
            resource_types=cached_data.get("resource_types", []),
            last_updated=cached_data.get("last_updated"),
            region=region,
            cache_status=cache_status,
            instruction=None
        )
        
    except Exception as e:
        logger.error(f"Error getting FIS actions: {e}")
        return FISActionsResponse(
            fis_actions=[],
            resource_types=[],
            last_updated=None,
            region=region,
            cache_status="error",
            instruction=f"Error accessing cache: {str(e)}. Please try refreshing the cache."
        )


@mcp.tool
def validate_fis_template(template: Dict[str, Any]) -> ValidationResponse:
    """Checks if a generated FIS experiment template uses valid action IDs and resource types.
    
    Validates action IDs and resource types against cached FIS capabilities.
    Does NOT validate IAM permissions, ARNs, or business logic.
    
    Args:
        template: FIS experiment template as a dictionary
        
    Returns:
        ValidationResponse with validation results and any errors found
    """
    try:
        logger.info("Validating FIS template")
        
        # Perform validation using the validator
        validation_result = validator.validate_template(template, fis_cache)
        
        return ValidationResponse(
            valid=validation_result["valid"],
            errors=validation_result["errors"],
            warnings=validation_result["warnings"],
            invalid_actions=validation_result["invalid_actions"],
            invalid_resource_types=validation_result["invalid_resource_types"],
            validation_timestamp=validation_result["validation_timestamp"]
        )
        
    except Exception as e:
        logger.error(f"Error validating template: {e}")
        return ValidationResponse(
            valid=False,
            errors=[f"Validation error: {str(e)}"],
            warnings=[],
            invalid_actions=[],
            invalid_resource_types=[],
            validation_timestamp=""
        )


@mcp.tool
def refresh_valid_fis_actions_cache(region: str = "us-east-1", fis_data: Optional[Dict[str, Any]] = None) -> CacheUpdateResponse:
    """Updates the cached FIS actions list with fresh data provided by agent from AWS MCP server.
    
    Args:
        region: AWS region for the data (default: us-east-1)
        fis_data: Fresh FIS data from AWS MCP server containing actions and resource types
        
    Returns:
        CacheUpdateResponse with updated cache status and timestamp
    """
    try:
        logger.info(f"Refreshing FIS actions cache for region: {region}")
        
        if not fis_data:
            return CacheUpdateResponse(
                success=False,
                message="No FIS data provided. Please provide fresh data from AWS MCP server.",
                last_updated=None,
                region=region
            )
        
        # Update the cache with fresh data
        success, message, timestamp = fis_cache.update_cache(region, fis_data)
        
        return CacheUpdateResponse(
            success=success,
            message=message,
            last_updated=timestamp,
            region=region
        )
        
    except Exception as e:
        logger.error(f"Error refreshing cache: {e}")
        return CacheUpdateResponse(
            success=False,
            message=f"Error updating cache: {str(e)}",
            last_updated=None,
            region=region
        )


@mcp.tool
def generate_fis_system_prompt(user_architecture: str, region: str = "us-east-1") -> SystemPromptResponse:
    """Generates a system prompt for FIS experiment creation with current AWS capabilities.
    
    Creates a complete system prompt that includes current FIS actions and resource types
    from the cache, along with the user's architecture description. This prompt can be
    used by agents to generate valid FIS experiment templates.
    
    Args:
        user_architecture: Description of the user's AWS architecture
        region: AWS region to get FIS data for (default: us-east-1)
        
    Returns:
        SystemPromptResponse with generated system prompt or error message
    """
    try:
        logger.info(f"Generating system prompt for region: {region}")
        
        # Get cached FIS data
        cached_data = fis_cache.get_cached_data(region)
        cache_status = fis_cache.get_cache_status(region)
        
        if cache_status in ["stale", "empty"]:
            return SystemPromptResponse(
                success=False,
                system_prompt="",
                message=f"Cannot generate system prompt: cache is {cache_status}. Please refresh the FIS actions cache first using refresh_valid_fis_actions_cache.",
                fis_actions_count=0,
                resource_types_count=0
            )
        
        # Extract FIS data from cache
        fis_actions = cached_data.get("fis_actions", [])
        resource_types = cached_data.get("resource_types", [])
        
        if not fis_actions or not resource_types:
            return SystemPromptResponse(
                success=False,
                system_prompt="",
                message="Cannot generate system prompt: no FIS actions or resource types available in cache.",
                fis_actions_count=len(fis_actions),
                resource_types_count=len(resource_types)
            )
        
        # Generate the complete system prompt
        system_prompt = generate_system_prompt(fis_actions, resource_types, user_architecture)
        
        return SystemPromptResponse(
            success=True,
            system_prompt=system_prompt,
            message="System prompt generated successfully with current FIS capabilities.",
            fis_actions_count=len(fis_actions),
            resource_types_count=len(resource_types)
        )
        
    except Exception as e:
        logger.error(f"Error generating system prompt: {e}")
        return SystemPromptResponse(
            success=False,
            system_prompt="",
            message=f"Error generating system prompt: {str(e)}",
            fis_actions_count=0,
            resource_types_count=0
        )


if __name__ == "__main__":
    mcp.run()