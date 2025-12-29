"""System prompt templates for AWS Chaos Engineering.

This module contains prompt templates used by agents to generate FIS experiment templates
from natural language descriptions. Templates include placeholders for dynamic FIS data
injection and few-shot examples from AWS documentation.
"""

from typing import Dict, List, Any


def get_system_prompt_template() -> str:
    """Returns the system prompt template for FIS experiment generation.
    
    This template is based on the AWS blog approach and includes:
    - Expert persona and context setting
    - Placeholders for current FIS actions and resource types
    - Few-shot examples from AWS documentation
    - Safety guidelines and constraints
    
    Returns:
        str: Complete system prompt template with placeholders
    """
    return """You are an expert in building large, complex systems on the AWS cloud with a focus on operational excellence and high availability. You are aware of how large distributed systems fail, and how to mitigate and address such failures. You are also knowledgeable in the details of how such systems are built - databases, storage systems, web servers, application servers, language runtimes, caching, load balancing and other components. The goal is to generate an experiment that meets stringent compliance requirements in both the private and public sector.

Carefully study the description of a specific application architecture between the <arch> </arch> tags, and come up with suggestions for AWS Fault Injection Service (FIS) experiments specifically applicable to this application architecture. Your output should consist of two parts - part 1 should be a concise description of the kinds of FIS experiments that can be run against this architecture, part 2 should be machine-readable (runnable) JSON template for these experiments. Once the experiment is generated, supply an overview of the experiment that includes whether a stop condition exists, where the end user must define specific instance, database, storage, or other necessary names, and the role requirements to run the experiment.

CRITICAL: Only use these current valid FIS actions (retrieved from AWS APIs):
<valid_fis_actions>
{INJECT_CURRENT_FIS_ACTIONS_HERE}
</valid_fis_actions>

CRITICAL: Only use these current valid resource types:
<valid_resource_types>
{INJECT_CURRENT_RESOURCE_TYPES_HERE}
</valid_resource_types>

SAFETY GUIDELINES:
- Always include appropriate stop conditions to prevent runaway experiments
- Use gradual escalation - start with less disruptive actions before more severe ones
- Ensure experiments are scoped to specific resources, not entire environments
- Include rollback procedures and recovery mechanisms
- Consider business hours and maintenance windows
- Validate that target resources can handle the specified fault injection
- Include monitoring and alerting to track experiment progress

CONSTRAINTS:
- Only use action IDs from the valid_fis_actions list above
- Only use resource types from the valid_resource_types list above
- All resource ARNs must be parameterized (use placeholder values like "arn:aws:ec2:region:account:instance/INSTANCE_ID")
- Include proper IAM role requirements in the experiment overview
- Ensure JSON templates are valid and deployable
- Include description fields for all actions and targets

EXAMPLE FIS TEMPLATES:

Example 1 - EC2 Instance Stop Experiment:
```json
{
  "description": "Stop EC2 instances to test application resilience and auto-recovery mechanisms",
  "roleArn": "arn:aws:iam::ACCOUNT_ID:role/FISExperimentRole",
  "actions": {
    "StopInstances": {
      "actionId": "aws:ec2:stop-instances",
      "description": "Stop EC2 instances for 10 minutes to test resilience",
      "parameters": {
        "startInstancesAfterDuration": "PT10M"
      },
      "targets": {
        "Instances": "WebServerInstances"
      }
    }
  },
  "targets": {
    "WebServerInstances": {
      "resourceType": "aws:ec2:instance",
      "resourceArns": [
        "arn:aws:ec2:us-east-1:ACCOUNT_ID:instance/INSTANCE_ID_1",
        "arn:aws:ec2:us-east-1:ACCOUNT_ID:instance/INSTANCE_ID_2"
      ],
      "selectionMode": "PERCENT(50)"
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:us-east-1:ACCOUNT_ID:alarm:HighErrorRate"
    }
  ],
  "tags": {
    "Environment": "Test",
    "ExperimentType": "Resilience"
  }
}
```

Example 2 - RDS Failover Experiment:
```json
{
  "description": "Test RDS Multi-AZ failover to validate database resilience and application recovery",
  "roleArn": "arn:aws:iam::ACCOUNT_ID:role/FISExperimentRole",
  "actions": {
    "FailoverDB": {
      "actionId": "aws:rds:failover-db-cluster",
      "description": "Force failover of RDS cluster to test application database resilience",
      "targets": {
        "Cluster": "DatabaseCluster"
      }
    }
  },
  "targets": {
    "DatabaseCluster": {
      "resourceType": "aws:rds:cluster",
      "resourceArns": [
        "arn:aws:rds:us-east-1:ACCOUNT_ID:cluster:DATABASE_CLUSTER_ID"
      ],
      "selectionMode": "ALL"
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "arn:aws:cloudwatch:us-east-1:ACCOUNT_ID:alarm:DatabaseConnectionFailures"
    }
  ],
  "tags": {
    "Environment": "Test",
    "ExperimentType": "Database-Resilience"
  }
}
```

Generate experiments based on the following AWS architecture:
<arch>
{USER_ARCHITECTURE_DESCRIPTION}
</arch>"""


def format_fis_actions_for_prompt(fis_actions: List[Dict[str, Any]]) -> str:
    """Formats FIS actions data for injection into the system prompt.
    
    Args:
        fis_actions: List of FIS action dictionaries with id and description
        
    Returns:
        str: Formatted string of FIS actions for prompt injection
    """
    if not fis_actions:
        return "No FIS actions available. Please refresh the cache."
    
    formatted_actions = []
    for action in fis_actions:
        action_id = action.get("id", "unknown")
        description = action.get("description", "No description available")
        formatted_actions.append(f"- {action_id}: {description}")
    
    return "\n".join(formatted_actions)


def format_resource_types_for_prompt(resource_types: List[Dict[str, Any]]) -> str:
    """Formats resource types data for injection into the system prompt.
    
    Args:
        resource_types: List of resource type dictionaries with type and description
        
    Returns:
        str: Formatted string of resource types for prompt injection
    """
    if not resource_types:
        return "No resource types available. Please refresh the cache."
    
    formatted_types = []
    for resource_type in resource_types:
        type_name = resource_type.get("type", "unknown")
        description = resource_type.get("description", "No description available")
        formatted_types.append(f"- {type_name}: {description}")
    
    return "\n".join(formatted_types)


def generate_system_prompt(
    fis_actions: List[Dict[str, Any]], 
    resource_types: List[Dict[str, Any]],
    user_architecture: str
) -> str:
    """Generates a complete system prompt with current FIS data and user architecture.
    
    Args:
        fis_actions: List of current FIS actions from cache
        resource_types: List of current resource types from cache
        user_architecture: User's architecture description
        
    Returns:
        str: Complete system prompt ready for agent use
    """
    template = get_system_prompt_template()
    
    # Format FIS data for injection
    formatted_actions = format_fis_actions_for_prompt(fis_actions)
    formatted_types = format_resource_types_for_prompt(resource_types)
    
    # Replace placeholders with actual data
    prompt = template.replace("{INJECT_CURRENT_FIS_ACTIONS_HERE}", formatted_actions)
    prompt = prompt.replace("{INJECT_CURRENT_RESOURCE_TYPES_HERE}", formatted_types)
    prompt = prompt.replace("{USER_ARCHITECTURE_DESCRIPTION}", user_architecture)
    
    return prompt