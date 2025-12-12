# AI-Powered Legacy System Automation with Nova Act

Automate workflows on legacy systems that were never built for automation using Amazon Nova Act's browser-based AI agents.

## The Problem

Many organizations rely on legacy systems with web interfaces but no APIs:
- Mainframe terminal emulators accessed via web browsers
- Legacy ERP systems with only UI-based workflows
- Internal tools built decades ago without integration capabilities
- Vendor systems where API access is unavailable or prohibitively expensive

Manual data entry, report extraction, and cross-system workflows on these systems consume significant operational time and are prone to human error.

## What This Demo Shows

This demo creates a database in phpMyAdmin using a single natural language instruction:

```python
nova.act(
    f"Click on 'New' in the left sidebar to create a new database. "
    f"Then enter '{db_name}' as the database name and click 'Create'."
)
```

That's it. Nova Act handles all the browser interactions - finding elements, clicking buttons, typing text, and navigating the UI - from one human-readable instruction.

This demonstrates how Nova Act can automate legacy web interfaces that lack APIs, enabling you to:

- Navigate complex legacy web interfaces
- Perform repetitive data entry across systems
- Extract data from legacy reports and dashboards
- Execute multi-step workflows that span multiple applications

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Legacy System  │◀───▶│   Nova Act       │◀───▶│   Orchestrator  │
│  (Web UI)       │     │   Browser Agent  │     │   (Python)      │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  AgentCore       │
                        │  Browser Tool    │
                        │  (Cloud Exec)    │
                        └──────────────────┘
```

**Components:**
- **Nova Act SDK**: Browser automation powered by Amazon Nova Act model
- **AgentCore Browser Tool**: Scalable cloud-based browser execution
- **Python Orchestrator**: Workflow coordination and error handling
- **Legacy System**: Any web-accessible application (simulated in demo)

## Prerequisites

- Python 3.10+
- AWS CLI v2 configured with credentials
- AWS Region set to `us-east-1` (Nova Act is currently only available in N. Virginia)
- PowerShell (Windows) or Bash (Linux/macOS)

### Required AWS Permissions

Your IAM user/role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "nova-act:CreateWorkflowDefinition",
        "nova-act:CreateWorkflowRun",
        "nova-act:GetWorkflowRun",
        "nova-act:ListWorkflowDefinitions",
        "nova-act:ListWorkflowRuns"
      ],
      "Resource": "*"
    }
  ]
}
```

For production deployments with AgentCore Browser Tool, additional permissions are required:
- `bedrock-agentcore:*` for AgentCore Runtime
- `s3:PutObject` for session recordings (optional)

## Quick Start

### One-Command Demo (Recommended)

The unified demo runner handles setup and execution in one step:

```powershell
# PowerShell (Windows)
cd operations-automation/legacy-system-automation
.\run-demo.ps1
```

```bash
# Bash (Linux/macOS)
cd operations-automation/legacy-system-automation
./run-demo.sh
```

This will:
1. Check Python 3.10+ is installed
2. Verify AWS credentials and set region to us-east-1
3. Install Nova Act SDK
4. Create the workflow definition (if needed)
5. Run the phpMyAdmin database creation demo

### Demo Options

```powershell
# Run with cleanup (delete database after demo)
.\run-demo.ps1 -Cleanup

# Run in headless mode (no browser window)
.\run-demo.ps1 -Headless

# Custom database name
.\run-demo.ps1 -DbName "my_test_db"

# Skip setup (if already configured)
.\run-demo.ps1 -SkipSetup

# Combine options
.\run-demo.ps1 -Cleanup -Headless
```

```bash
# Bash equivalents
./run-demo.sh --cleanup
./run-demo.sh --headless
./run-demo.sh --db-name "my_test_db"
./run-demo.sh --skip-setup
./run-demo.sh --cleanup --headless
```

### Manual Setup (Alternative)

If you prefer to set up manually:

```powershell
# 1. Install dependencies
pip install nova-act

# 2. Set region and create workflow
aws configure set region us-east-1
aws nova-act create-workflow-definition --name "legacy-system-automation"

# 3. Run the demo
python create_database.py
```

## Demo Scenarios

### Scenario 1: Legacy Report Extraction
Automatically navigate to a legacy reporting system, generate a report with specific parameters, and extract the data.

```python
from nova_act import NovaAct

async with NovaAct(api_key=api_key) as nova:
    # Navigate to legacy reporting portal
    await nova.act("Go to the legacy reporting portal at https://legacy-app.example.com")
    
    # Login with credentials
    await nova.act("Enter username 'operator' and password, then click Login")
    
    # Navigate to reports section
    await nova.act("Click on 'Reports' in the main menu, then select 'Monthly Summary'")
    
    # Set report parameters and generate
    await nova.act("Set date range to last month, select 'All Departments', click Generate")
    
    # Extract the report data
    result = await nova.act("Extract all data from the report table")
```

### Scenario 2: Cross-System Data Entry
Transfer data from one legacy system to another without manual copy-paste.

### Scenario 3: Automated Compliance Checks
Navigate through legacy audit interfaces to verify compliance status across systems.

## Usage Patterns

### Basic Navigation and Action

```python
from nova_act import NovaAct

async def automate_legacy_workflow():
    # Uses AWS IAM credentials automatically
    async with NovaAct(workflow_definition_name="legacy-system-automation") as nova:
        # Nova Act understands natural language instructions
        await nova.act("Navigate to the inventory management system")
        await nova.act("Search for product SKU 'ABC-12345'")
        await nova.act("Update the quantity to 150 and save changes")
```

### Data Extraction

```python
async def extract_legacy_data():
    async with NovaAct(workflow_definition_name="legacy-system-automation") as nova:
        await nova.act("Go to the customer database portal")
        await nova.act("Search for customers with status 'Pending Review'")
        
        # Extract structured data from the page
        customers = await nova.act(
            "Extract all customer records from the table, "
            "including name, email, status, and last activity date"
        )
        return customers
```

### Error Handling and Retries

```python
async def robust_automation():
    async with NovaAct(workflow_definition_name="legacy-system-automation") as nova:
        try:
            await nova.act("Submit the form and wait for confirmation")
        except Exception as e:
            # Nova Act can recover from unexpected UI states
            await nova.act("If there's an error message, click OK and try again")
```

## Cloud Execution with AgentCore

For production workloads, use AgentCore Browser Tool for scalable cloud execution:

```python
from strands import Agent
from strands_tools import browser

# Create agent with browser tool
agent = Agent(tools=[browser])

# Execute browser automation at scale
response = agent(
    "Navigate to the legacy HR system, "
    "find all employees with pending timesheet approvals, "
    "and export the list to CSV"
)
```

## Cost Estimates

### Nova Act Pricing
Nova Act charges based on browser session time and actions performed.

| Usage Level | Sessions/Month | Estimated Cost |
|-------------|----------------|----------------|
| Development | 100 | ~$50-100/month |
| Light Production | 500 | ~$250-500/month |
| Heavy Production | 2000+ | Contact AWS |

### AgentCore Browser Tool (Cloud Execution)
- Browser session time: Varies by region
- See [AgentCore pricing](https://aws.amazon.com/bedrock/agentcore/pricing/) for details

### Cost Optimization Tips
- Batch similar operations to reduce session overhead
- Use headless mode when visual verification isn't needed
- Cache authentication tokens where possible
- Implement smart waiting instead of fixed delays

## Troubleshooting

### Nova Act Can't Find Element
- Be more specific in your natural language instructions
- Break complex actions into smaller steps
- Use visual descriptions ("the blue Submit button at the bottom")

### Session Timeout
- Legacy systems often have aggressive session timeouts
- Implement keep-alive actions for long workflows
- Consider breaking workflows into smaller sessions

### Authentication Issues
- Some legacy systems use non-standard auth flows
- Nova Act can handle most login forms automatically
- For complex auth (MFA, certificates), pre-authenticate and pass session

### Debugging Commands

```python
# Enable verbose logging
import logging
logging.basicConfig(level=logging.DEBUG)

# Take screenshots for debugging
await nova.act("Take a screenshot and save it")

# Get current page state
state = await nova.act("Describe what you see on the current page")
print(state)
```

## Security Considerations

- **AWS IAM**: Nova Act uses your AWS credentials - no separate API keys to manage
- **Credentials for Legacy Systems**: Store legacy system credentials in AWS Secrets Manager
- **Session Isolation**: Each Nova Act session runs in an isolated browser instance
- **Network Access**: Ensure Nova Act can reach your legacy systems (VPN/firewall considerations)
- **Audit Logging**: Workflow runs are tracked in AWS Console; enable S3 export for full audit trails
- **Least Privilege**: Use service accounts with minimal required permissions for both AWS and legacy systems

## Files

| File | Description |
|------|-------------|
| `run-demo.ps1` | One-click demo runner (Windows) - setup + execution |
| `run-demo.sh` | One-click demo runner (Linux/macOS) - setup + execution |
| `create_database.py` | Main demo script - creates database in phpMyAdmin |
| `install-nova-act-workflow.ps1` | Setup-only script (Windows) |
| `install-nova-act-workflow.sh` | Setup-only script (Linux/macOS) |
| `requirements.txt` | Python dependencies |
| `ARCHITECTURE.md` | Technical architecture details |

## Alternative: Nova Act IDE Extension

For interactive development, install the [Nova Act IDE Extension](https://github.com/aws/nova-act-extension) for VS Code, Kiro, or Cursor. The extension provides:

- **Step-by-step builder**: Notebook-style interface to test each action individually
- **Live debugging**: Watch the browser in real-time as your agent executes
- **Chat-to-script**: Describe your automation in natural language, get working code
- **One-click deploy**: Deploy workflows to AWS directly from the IDE
- **Pre-built templates**: Start with examples for QA testing, data extraction, form automation

Install from VS Code Marketplace or run `Nova Act: Start Walkthrough` from the Command Palette.

## Next Steps

1. **Try the Playground**: Experiment at [nova.amazon.com/act](https://nova.amazon.com/act) before writing code
2. **Install IDE Extension**: Use the [Nova Act extension](https://github.com/aws/nova-act-extension) in VS Code, Kiro, or Cursor
3. **Monitor in Console**: View workflow runs in the [Nova Act AWS Console](https://console.aws.amazon.com/nova-act/)
4. **Scale with AgentCore**: Move to cloud execution for production workloads

## Resources

- [Amazon Nova Act Documentation](https://aws.amazon.com/nova/act/)
- [Nova Act SDK Guide](https://docs.aws.amazon.com/nova-act/)
- [Nova Act IDE Extension](https://github.com/aws/nova-act-extension)
- [AgentCore Browser Tool](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/browser-building-agents.html)
- [Strands Agents Framework](https://github.com/strands-agents/strands-agents)
