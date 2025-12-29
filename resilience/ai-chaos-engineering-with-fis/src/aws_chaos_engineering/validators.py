"""FIS template validation.

This module provides validation for FIS experiment templates against
cached AWS capabilities, focusing on action IDs and resource types only.
"""

from datetime import datetime, timezone
from typing import Dict, Any, List, Set
import logging

logger = logging.getLogger(__name__)


class FISTemplateValidator:
    """Validates FIS experiment templates against cached AWS capabilities."""
    
    def __init__(self):
        """Initialize the FIS template validator."""
        pass
    
    def _extract_action_ids(self, template: Dict[str, Any]) -> Set[str]:
        """Extract action IDs from a FIS template.
        
        Args:
            template: FIS experiment template
            
        Returns:
            Set of action IDs found in the template
        """
        action_ids = set()
        
        try:
            # Look for actions in the template
            actions = template.get("actions", {})
            if isinstance(actions, dict):
                for action_config in actions.values():
                    if isinstance(action_config, dict):
                        action_id = action_config.get("actionId")
                        if action_id:
                            action_ids.add(action_id)
            
            # Also check Resources section for action references
            resources = template.get("Resources", {})
            if isinstance(resources, dict):
                for resource in resources.values():
                    if isinstance(resource, dict):
                        properties = resource.get("Properties", {})
                        if isinstance(properties, dict):
                            actions_prop = properties.get("Actions", {})
                            if isinstance(actions_prop, dict):
                                for action_config in actions_prop.values():
                                    if isinstance(action_config, dict):
                                        action_id = action_config.get("ActionId")
                                        if action_id:
                                            action_ids.add(action_id)
            
        except Exception as e:
            logger.warning(f"Error extracting action IDs: {e}")
        
        return action_ids
    
    def _extract_resource_types(self, template: Dict[str, Any]) -> Set[str]:
        """Extract resource types from a FIS template.
        
        Args:
            template: FIS experiment template
            
        Returns:
            Set of resource types found in the template
        """
        resource_types = set()
        
        try:
            # Look for targets in the template
            targets = template.get("targets", {})
            if isinstance(targets, dict):
                for target_config in targets.values():
                    if isinstance(target_config, dict):
                        resource_type = target_config.get("resourceType")
                        if resource_type:
                            resource_types.add(resource_type)
            
            # Also check Resources section for target references
            resources = template.get("Resources", {})
            if isinstance(resources, dict):
                for resource in resources.values():
                    if isinstance(resource, dict):
                        properties = resource.get("Properties", {})
                        if isinstance(properties, dict):
                            targets_prop = properties.get("Targets", {})
                            if isinstance(targets_prop, dict):
                                for target_config in targets_prop.values():
                                    if isinstance(target_config, dict):
                                        resource_type = target_config.get("ResourceType")
                                        if resource_type:
                                            resource_types.add(resource_type)
            
        except Exception as e:
            logger.warning(f"Error extracting resource types: {e}")
        
        return resource_types
    
    def _get_valid_action_ids(self, fis_cache) -> Set[str]:
        """Get set of valid action IDs from cache.
        
        Args:
            fis_cache: FISCache instance
            
        Returns:
            Set of valid action IDs
        """
        valid_actions = set()
        
        try:
            # Try to get cached data for common regions
            for region in ["us-east-1", "us-west-2", "eu-west-1"]:
                cached_data = fis_cache.get_cached_data(region)
                if cached_data and fis_cache.get_cache_status(region) == "fresh":
                    fis_actions = cached_data.get("fis_actions", [])
                    for action in fis_actions:
                        if isinstance(action, dict):
                            action_id = action.get("id")
                            if action_id:
                                valid_actions.add(action_id)
                    break  # Use first available fresh cache
            
        except Exception as e:
            logger.warning(f"Error getting valid action IDs: {e}")
        
        return valid_actions
    
    def _get_valid_resource_types(self, fis_cache) -> Set[str]:
        """Get set of valid resource types from cache.
        
        Args:
            fis_cache: FISCache instance
            
        Returns:
            Set of valid resource types
        """
        valid_types = set()
        
        try:
            # Try to get cached data for common regions
            for region in ["us-east-1", "us-west-2", "eu-west-1"]:
                cached_data = fis_cache.get_cached_data(region)
                if cached_data and fis_cache.get_cache_status(region) == "fresh":
                    resource_types = cached_data.get("resource_types", [])
                    for resource_type in resource_types:
                        if isinstance(resource_type, dict):
                            type_name = resource_type.get("type")
                            if type_name:
                                valid_types.add(type_name)
                    break  # Use first available fresh cache
            
        except Exception as e:
            logger.warning(f"Error getting valid resource types: {e}")
        
        return valid_types
    
    def validate_template(self, template: Dict[str, Any], fis_cache) -> Dict[str, Any]:
        """Validate a FIS template against cached capabilities.
        
        Validates only action IDs and resource types. Does NOT validate:
        - IAM permissions
        - ARNs or resource identifiers
        - Business logic or experiment design
        
        Args:
            template: FIS experiment template to validate
            fis_cache: FISCache instance for getting valid capabilities
            
        Returns:
            Dictionary with validation results
        """
        validation_result = {
            "valid": True,
            "errors": [],
            "warnings": [],
            "invalid_actions": [],
            "invalid_resource_types": [],
            "validation_timestamp": datetime.now(timezone.utc).isoformat()
        }
        
        try:
            # Extract action IDs and resource types from template
            template_actions = self._extract_action_ids(template)
            template_resource_types = self._extract_resource_types(template)
            
            # Get valid capabilities from cache
            valid_actions = self._get_valid_action_ids(fis_cache)
            valid_resource_types = self._get_valid_resource_types(fis_cache)
            
            # Check if we have cached data to validate against
            if not valid_actions and not valid_resource_types:
                validation_result["warnings"].append(
                    "No cached FIS capabilities available for validation. "
                    "Please refresh the cache with current AWS data."
                )
                return validation_result
            
            # Validate action IDs
            invalid_actions = template_actions - valid_actions
            if invalid_actions:
                validation_result["valid"] = False
                validation_result["invalid_actions"] = list(invalid_actions)
                for action_id in invalid_actions:
                    validation_result["errors"].append(
                        f"Invalid action ID: '{action_id}'. "
                        f"This action is not available in the current AWS FIS capabilities."
                    )
            
            # Validate resource types
            invalid_resource_types = template_resource_types - valid_resource_types
            if invalid_resource_types:
                validation_result["valid"] = False
                validation_result["invalid_resource_types"] = list(invalid_resource_types)
                for resource_type in invalid_resource_types:
                    validation_result["errors"].append(
                        f"Invalid resource type: '{resource_type}'. "
                        f"This resource type is not supported by AWS FIS."
                    )
            
            # Add informational warnings
            if template_actions and valid_actions:
                validation_result["warnings"].append(
                    f"Validated {len(template_actions)} action IDs against "
                    f"{len(valid_actions)} available FIS actions."
                )
            
            if template_resource_types and valid_resource_types:
                validation_result["warnings"].append(
                    f"Validated {len(template_resource_types)} resource types against "
                    f"{len(valid_resource_types)} available resource types."
                )
            
            # Note validation scope limitations
            validation_result["warnings"].append(
                "Validation covers only action IDs and resource types. "
                "IAM permissions, ARNs, and business logic are not validated."
            )
            
        except Exception as e:
            logger.error(f"Error during template validation: {e}")
            validation_result["valid"] = False
            validation_result["errors"].append(f"Validation error: {str(e)}")
        
        return validation_result