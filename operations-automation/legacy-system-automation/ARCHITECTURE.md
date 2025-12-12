# Architecture - AI-Powered Legacy System Automation

## Overview

This demo implements browser-based automation for legacy systems using Amazon Nova Act. The solution enables automation of web interfaces that lack APIs, using AI-powered browser agents that understand natural language instructions and can navigate complex UI workflows.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Orchestration Layer                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │
│  │  Python Script  │  │  Strands Agent  │  │  CI/CD Pipeline │         │
│  │  (Local Dev)    │  │  (Multi-Agent)  │  │  (Scheduled)    │         │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘         │
└───────────┼────────────────────┼────────────────────┼───────────────────┘
            │                    │                    │
            ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Nova Act SDK Layer                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     Nova Act Python SDK                          │   │
│  │  • Natural language action interpretation                        │   │
│  │  • Browser session management                                    │   │
│  │  • Error recovery and retry logic                               │   │
│  │  • Data extraction and structuring                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Execution Layer                                  │
│  ┌─────────────────────┐          ┌─────────────────────┐              │
│  │   Local Browser     │    OR    │  AgentCore Browser  │              │
│  │   (Development)     │          │  Tool (Production)  │              │
│  │                     │          │                     │              │
│  │  • Playwright       │          │  • Cloud execution  │              │
│  │  • Chrome/Chromium  │          │  • Auto-scaling     │              │
│  │  • Visual debugging │          │  • Session mgmt     │              │
│  └──────────┬──────────┘          └──────────┬──────────┘              │
└─────────────┼────────────────────────────────┼──────────────────────────┘
              │                                │
              ▼                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Target Systems                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │ Legacy ERP  │  │ Mainframe   │  │ Internal    │  │ Vendor      │   │
│  │ Web Portal  │  │ Web Term    │  │ Tools       │  │ Portals     │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Nova Act SDK

The core automation engine powered by Amazon Nova Act model.

**Capabilities:**
- Natural language instruction interpretation
- Visual understanding of web interfaces
- Intelligent element location and interaction
- Context-aware navigation
- Data extraction and structuring

**Key Features:**
- **Reliability**: >90% task completion rate on enterprise workflows
- **Adaptability**: Handles UI changes without script modifications
- **Recovery**: Automatic error detection and recovery attempts

### 2. Orchestration Layer

Coordinates automation workflows and integrates with existing systems.

**Local Development (Python Script)**
```python
from nova_act import NovaAct

async with NovaAct(api_key=api_key) as nova:
    await nova.act("Navigate to legacy system")
    await nova.act("Perform workflow steps")
```

**Multi-Agent (Strands Framework)**
```python
from strands import Agent
from strands_tools import browser

agent = Agent(tools=[browser])
agent("Complete the legacy workflow")
```

**Scheduled Execution (CI/CD)**
- GitHub Actions, AWS CodePipeline, or cron-based triggers
- Batch processing of accumulated tasks
- Scheduled report generation

### 3. Execution Layer

**Local Browser (Development)**
- Uses Playwright with Chrome/Chromium
- Visual debugging with headed mode
- Screenshot capture for troubleshooting
- Fast iteration during development

**AgentCore Browser Tool (Production)**
- Serverless cloud-based browser execution
- Automatic scaling for parallel workflows
- Session recording and playback
- Enterprise security controls

### 4. Target Systems

Legacy systems accessed via browser automation:

| System Type | Examples | Common Workflows |
|-------------|----------|------------------|
| Legacy ERP | SAP GUI for HTML, Oracle Forms | Data entry, report extraction |
| Mainframe Web | IBM Host on-Demand, Attachmate | Transaction processing |
| Internal Tools | Custom PHP/ASP apps | Status updates, approvals |
| Vendor Portals | Supplier/partner systems | Order management, data sync |

## Data Flow

### Workflow Execution Flow

```
1. Trigger
   ├── Manual execution (development)
   ├── Scheduled job (production)
   └── Event-driven (webhook, queue)
           │
           ▼
2. Orchestrator
   ├── Load workflow definition
   ├── Retrieve credentials (Secrets Manager)
   └── Initialize Nova Act session
           │
           ▼
3. Nova Act SDK
   ├── Parse natural language instructions
   ├── Plan action sequence
   └── Execute browser actions
           │
           ▼
4. Browser Execution
   ├── Navigate to target system
   ├── Authenticate
   ├── Perform workflow steps
   └── Extract results
           │
           ▼
5. Result Processing
   ├── Validate extracted data
   ├── Transform to target format
   ├── Store/forward results
   └── Log completion status
```

### Data Extraction Flow

```
Legacy System UI
       │
       ▼
┌──────────────────┐
│  Nova Act reads  │
│  page content    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  AI interprets   │
│  data structure  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Structured JSON │
│  output          │
└────────┬─────────┘
         │
         ▼
   Target System
   (S3, Database, API)
```

## Security Design

### Credential Management

```
┌─────────────────────────────────────────────────────────┐
│                  Secrets Manager                         │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │ Legacy System   │  │ Nova Act        │              │
│  │ Credentials     │  │ API Key         │              │
│  └────────┬────────┘  └────────┬────────┘              │
└───────────┼────────────────────┼────────────────────────┘
            │                    │
            ▼                    ▼
┌─────────────────────────────────────────────────────────┐
│                  Orchestrator                            │
│  • Retrieves secrets at runtime                         │
│  • Never logs credentials                               │
│  • Rotates sessions after use                           │
└─────────────────────────────────────────────────────────┘
```

### Network Security

**For Cloud Execution:**
- AgentCore Browser runs in AWS-managed VPC
- VPC peering or PrivateLink for internal systems
- Security groups control egress to legacy systems

**For Local Execution:**
- Browser runs on local machine
- VPN connection for internal systems
- Corporate firewall rules apply

### Session Isolation

- Each automation run uses isolated browser instance
- No shared cookies or local storage between runs
- Session data cleared after workflow completion

### Audit Logging

```python
# All actions logged with timestamps
{
    "timestamp": "2025-12-12T10:30:00Z",
    "workflow_id": "legacy-report-extraction-001",
    "action": "navigate",
    "target": "https://legacy-erp.internal/reports",
    "status": "success",
    "duration_ms": 1250
}
```

## Reliability Patterns

### Retry with Backoff

```python
async def reliable_action(nova, instruction, max_retries=3):
    for attempt in range(max_retries):
        try:
            return await nova.act(instruction)
        except Exception as e:
            if attempt < max_retries - 1:
                await asyncio.sleep(2 ** attempt)
                await nova.act("If there's an error dialog, dismiss it")
            else:
                raise
```

### State Verification

```python
async def verified_navigation(nova, target_page):
    await nova.act(f"Navigate to {target_page}")
    
    # Verify we reached the correct page
    verification = await nova.act(
        f"Confirm you are on the {target_page} page. "
        "Return 'confirmed' or 'wrong_page'"
    )
    
    if "wrong_page" in verification.lower():
        raise NavigationError(f"Failed to reach {target_page}")
```

### Graceful Degradation

```python
async def extract_with_fallback(nova):
    try:
        # Try structured extraction
        data = await nova.act("Extract table data as JSON")
        return json.loads(data)
    except:
        # Fall back to text extraction
        text = await nova.act("Copy all visible text from the table")
        return {"raw_text": text}
```

## Scalability Considerations

### Parallel Execution

```python
import asyncio

async def parallel_workflows(systems):
    tasks = [
        automate_system(system) 
        for system in systems
    ]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return results
```

### Queue-Based Processing

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   SQS       │────▶│   Lambda    │────▶│  Nova Act   │
│   Queue     │     │   Trigger   │     │  Execution  │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Rate Limiting

- Respect legacy system capacity limits
- Implement delays between actions if needed
- Use queuing for high-volume scenarios

## Monitoring and Observability

### Metrics to Track

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Success Rate | % of workflows completed | < 90% |
| Duration | Time to complete workflow | > 2x baseline |
| Error Rate | Failed actions per workflow | > 5% |
| Session Count | Concurrent browser sessions | > limit |

### CloudWatch Integration

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def log_metric(workflow_name, success, duration):
    cloudwatch.put_metric_data(
        Namespace='LegacyAutomation',
        MetricData=[
            {
                'MetricName': 'WorkflowSuccess',
                'Dimensions': [{'Name': 'Workflow', 'Value': workflow_name}],
                'Value': 1 if success else 0
            },
            {
                'MetricName': 'WorkflowDuration',
                'Dimensions': [{'Name': 'Workflow', 'Value': workflow_name}],
                'Value': duration,
                'Unit': 'Seconds'
            }
        ]
    )
```

## Extension Points

### Custom Actions

Extend Nova Act with domain-specific actions:

```python
class LegacyERPAutomation:
    def __init__(self, nova):
        self.nova = nova
    
    async def login(self, username, password):
        await self.nova.act(f"Enter username '{username}'")
        await self.nova.act("Enter password and click Login")
        await self.nova.act("Wait for dashboard to load")
    
    async def run_report(self, report_name, params):
        await self.nova.act(f"Navigate to Reports > {report_name}")
        for key, value in params.items():
            await self.nova.act(f"Set {key} to {value}")
        await self.nova.act("Click Generate Report")
```

### Integration with Existing Tools

- **ServiceNow**: Trigger automation from incident tickets
- **Slack/Teams**: Notify on completion or failure
- **S3**: Store extracted data and screenshots
- **Step Functions**: Orchestrate complex multi-system workflows

## Why Nova Act for Legacy Automation?

| Challenge | Traditional RPA | Nova Act |
|-----------|-----------------|----------|
| UI Changes | Scripts break | AI adapts automatically |
| Complex Navigation | Brittle selectors | Natural language instructions |
| Data Extraction | Manual mapping | AI understands context |
| Maintenance | High ongoing effort | Self-healing capabilities |
| Development Speed | Weeks | Hours to days |

Nova Act's AI-powered approach provides resilience against the UI changes and inconsistencies common in legacy systems, reducing maintenance burden and improving reliability.
