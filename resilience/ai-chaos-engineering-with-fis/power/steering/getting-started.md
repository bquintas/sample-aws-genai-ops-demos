# Getting Started with AWS Chaos Engineering

This guide provides step-by-step instructions for using the AWS Chaos Engineering Kiro Power to generate and validate AWS FIS experiment templates through natural language descriptions.

## Prerequisites

Before using this power, ensure you have:

1. **AWS Account Access**: Valid AWS credentials configured
2. **AWS FIS Service**: Available in your target region
3. **Kiro Setup**: Kiro installed with MCP server support
4. **AWS MCP Server**: Configured for AWS API access

## Step 1: Power Activation

The power activates automatically when you mention chaos engineering keywords in your conversation:

**Trigger Keywords:**
- "chaos engineering"
- "fault injection" 
- "resilience testing"
- "AWS FIS"
- "experiment template"
- "failure testing"
- "disaster recovery testing"

**Example Activation:**
```
"I want to create a chaos engineering experiment to test my RDS failover capabilities"
```

## Step 2: Describe Your Architecture

Provide a clear description of your AWS architecture and the specific failure scenario you want to test:

**Good Architecture Description:**
```
I have a web application running on:
- EC2 instances in an Auto Scaling Group across 2 AZs
- Application Load Balancer distributing traffic
- RDS MySQL database with Multi-AZ deployment
- ElastiCache Redis cluster for session storage

I want to test what happens when the primary RDS instance fails.
```

**Include These Details:**
- AWS services involved (EC2, RDS, ELB, etc.)
- Architecture topology (multi-AZ, regions, etc.)
- Specific failure scenario you want to simulate
- Expected recovery mechanisms

## Step 3: Review Generated Template

The agent will:

1. **Fetch Current FIS Capabilities**: Retrieve latest AWS FIS actions and resource types
2. **Generate Experiment Template**: Create a JSON CloudFormation template
3. **Validate Template**: Check against current AWS capabilities
4. **Provide Deployment Guidance**: Include setup instructions and safety considerations

**Template Components:**
- **Actions**: Specific fault injection actions (e.g., `aws:rds:failover-db-cluster`)
- **Targets**: Resource selection criteria
- **Stop Conditions**: Safety mechanisms to halt experiments
- **IAM Roles**: Required permissions for execution

## Step 4: Safety Review

**CRITICAL**: Always review the generated template for:

### Stop Conditions
- Verify appropriate CloudWatch alarms are configured
- Ensure stop conditions will trigger before customer impact
- Test stop conditions in non-production first

### Target Selection
- Confirm resource selection criteria are correct
- Verify tags and filters target intended resources only
- Double-check resource ARNs and identifiers

### Blast Radius
- Ensure experiment scope is appropriate for your environment
- Start with single resources before scaling to multiple
- Consider dependencies and downstream impacts

## Step 5: Deploy and Execute

1. **Deploy Template**: Use AWS CloudFormation console or CLI
2. **Configure Parameters**: Set resource-specific values (instance IDs, etc.)
3. **Review Permissions**: Ensure FIS service role has required permissions
4. **Start Small**: Begin with single resource experiments
5. **Monitor Closely**: Watch stop conditions and system behavior

## Common First Experiments

### RDS Failover Test
```
"Create a chaos experiment to test RDS Multi-AZ failover for my production database cluster"
```

### EC2 Instance Failure
```
"I want to simulate EC2 instance failure in my auto scaling group to test recovery"
```

### Network Partition
```
"Create an experiment to test network connectivity issues between my application and database tiers"
```

## Safety Guidelines

### Pre-Experiment Checklist
- [ ] Experiment runs in non-production environment first
- [ ] Stop conditions configured and tested
- [ ] Monitoring and alerting active
- [ ] Rollback procedures documented
- [ ] Team notified of experiment schedule

### During Experiment
- [ ] Monitor stop conditions continuously
- [ ] Watch for unexpected behavior
- [ ] Be ready to manually stop experiment
- [ ] Document observations and metrics

### Post-Experiment
- [ ] Verify system recovery
- [ ] Analyze results and metrics
- [ ] Document lessons learned
- [ ] Update runbooks based on findings

## Troubleshooting

### Power Not Activating
- Ensure you use chaos engineering keywords
- Check MCP server configuration in Kiro
- Verify aws-chaos-engineering server is running

### Template Validation Errors
- Check if AWS FIS actions are available in your region
- Verify resource types match your architecture
- Ensure you have latest FIS capabilities cached

### Deployment Issues
- Verify IAM permissions for FIS service role
- Check CloudFormation template syntax
- Ensure target resources exist and are properly tagged

## Next Steps

Once comfortable with basic experiments:
1. Review [Advanced Patterns](advanced-patterns.md) for complex scenarios
2. Integrate experiments into CI/CD pipelines
3. Automate experiment scheduling and analysis
4. Build comprehensive chaos engineering program

## Support

For issues with:
- **Power functionality**: Check MCP server logs and configuration
- **AWS FIS service**: Consult AWS FIS documentation and support
- **Template deployment**: Review CloudFormation error messages