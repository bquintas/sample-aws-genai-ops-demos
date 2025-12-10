# AWS GenAI Operations Demos

This repository contains deployable code samples demonstrating practical applications of generative AI for cloud operations. Each demo provides working implementations that can be deployed in your AWS environment.

## Available Demos

### Security
| Demo Name | Description | Repository |
|-----------|-------------|------------|
| Secure Coding with Kiro Hooks | Automated security analysis in development workflows | `security/secure-coding-kiro-hooks/` |
| Compliance Gap Analysis with AI | Automated compliance scanning and remediation guidance | `security/compliance-gap-analysis/` |

### Cost Optimization
| Demo Name | Description | Repository |
|-----------|-------------|------------|
| GenAI Cost Optimization MCP Server | Proactive cost analysis for AI workloads | `cost-optimization/genai-cost-optimization-mcp/` |

### Observability
| Demo Name | Description | Repository |
|-----------|-------------|------------|
| AI-Powered Incident Analysis | Automated root cause analysis using AI | `observability/incident-analysis/` |
| GenAI Workload Observability & Anomaly Detection | AI-powered monitoring for GenAI usage patterns and anomalies | `observability/genai-workload-monitoring/` |

### Resilience
| Demo Name | Description | Repository |
|-----------|-------------|------------|
| Automated Resilience Testing & Recovery | AI-driven chaos engineering and recovery automation | `resilience/automated-resilience-testing/` |
| GenAI-Powered Capacity Management | Predictive capacity planning for GenAI workloads | `resilience/genai-capacity-management/` |

### Operations Automation
| Demo Name | Description | Repository |
|-----------|-------------|------------|
| AWS Services Lifecycle Tracker | Automated monitoring of AWS service deprecations and end-of-life notices | [External Repository](https://github.com/aws-samples/sample-genai-powered-end-of-life-tracker) |
| Model Upgrade Evaluator | Automated testing framework for AI model migrations | `operations-automation/model-upgrade-evaluator/` |
| AI-Powered Legacy System Automation | Automate workflows on systems never built for automation | `operations-automation/legacy-system-automation/` |

## Repository Structure

```
security/
├── secure-coding-kiro-hooks/
├── compliance-gap-analysis/
cost-optimization/
├── genai-cost-optimization-mcp/
observability/
├── incident-analysis/
├── genai-workload-monitoring/
resilience/
├── automated-resilience-testing/
├── genai-capacity-management/
operations-automation/
├── model-upgrade-evaluator/
└── legacy-system-automation/
```

Each demo folder contains:
```
[demo-name]/
├── README.md              # Deployment guide
├── ARCHITECTURE.md        # Technical design
├── src/                   # Source code
├── deployment/            # Infrastructure as Code
└── sample-data/           # Test scenarios (if applicable)
```

## Getting Started

1. Choose a demo from the list above
2. Navigate to the demo's folder: `[pillar]/[demo-name]/`
3. Follow the README.md for deployment instructions
4. Deploy using the provided Infrastructure as Code scripts

## Prerequisites

- AWS CLI configured with appropriate permissions
- AWS CDK or Terraform (depending on demo)
- Node.js 18+ (for CDK-based demos)
- Python 3.9+ (for Python-based demos)

## Technology Stack

### Core AI Services
- **Amazon Bedrock** - Foundation model access and management
- **Amazon Nova Models** - Latest generation AI models
- **Amazon Bedrock AgentCore** - Multi-step AI workflow orchestration

### Integration Frameworks
- **Model Context Protocol (MCP) Servers** - Standardized tool integration
- **Kiro** - AI-assisted development workflows

### Supporting Services
- **AWS Lambda** - Serverless compute
- **Amazon CloudWatch** - Monitoring and logging
- **AWS Systems Manager** - Configuration management
- **Amazon S3** - Object storage
- **Amazon DynamoDB** - NoSQL database

## Cost Considerations

Each demo includes detailed cost estimates and optimization recommendations. Typical costs range from $10-50/month depending on usage patterns. See individual demo READMEs for specific cost breakdowns.



## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

