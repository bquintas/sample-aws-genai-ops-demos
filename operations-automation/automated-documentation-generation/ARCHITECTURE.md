# Architecture - Automated Documentation Generation

## Overview

This demo implements automated technical documentation generation using AWS Transform's comprehensive codebase analysis capability. The solution uses CodeBuild to process Git repositories and generate comprehensive documentation including architecture analysis, security configurations, and operational procedures.

## Architecture Diagram

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Git Repo      │────▶│   CodeBuild      │────▶│   S3 Bucket     │
│   (any URL)     │     │   + AWS Transform│     │   (docs output) │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  CloudWatch Logs │
                        │  (monitoring)    │
                        └──────────────────┘
```

## Components

### 1. CodeBuild Project
- **Name**: `aws-transform-doc-generator`
- **Image**: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`
- **Compute**: `BUILD_GENERAL1_MEDIUM` (4 vCPU, 7 GB RAM)
- **Timeout**: 60 minutes
- **Key Functions**:
  - Clone Git repositories
  - Install AWS Transform CLI
  - Execute comprehensive codebase analysis
  - Upload results to S3

### 2. S3 Bucket

**Output Bucket** (`doc-gen-output-{account}-{region}`)
- **Purpose**: Store generated documentation and buildspec
- **Structure**:
  ```
  s3://doc-gen-output-{account}-{region}/
  ├── config/
  │   └── buildspec.yml          # Build specification
  └── documentation/
      └── {job-id}/              # Generated docs per job
          ├── Documentation/     # AWS Transform output
          ├── README.md
          └── ...
  ```
- **Access**: Private, accessed via IAM role

### 3. IAM Role

**CodeBuildDocGenRole**
- **Trust Policy**: CodeBuild service
- **Attached Policies**:
  - `CloudWatchLogsFullAccess` - Build logging
  - `AmazonS3FullAccess` - Documentation storage
  - `TransformCustomPolicy` - AWS Transform access (`transform-custom:*`)

### 4. AWS Transform Integration
- **CLI**: Installed via `https://desktop-release.transform.us-east-1.api.aws/install.sh`
- **Transformation**: `AWS/early-access-comprehensive-codebase-analysis`
- **Execution**: `atx custom def exec -n "AWS/early-access-comprehensive-codebase-analysis" -p "." -x -t`
- **Output**: Comprehensive technical documentation in markdown format

## Build Phases

### Phase 1: Install
```yaml
install:
  runtime-versions:
    python: 3.11
    nodejs: 22
  commands:
    - Install AWS Transform CLI
    - Install boto3 for S3 operations
```

### Phase 2: Pre-Build
```yaml
pre_build:
  commands:
    - Clone target repository (shallow clone)
    - Validate repository structure
```

### Phase 3: Build
```yaml
build:
  commands:
    - Run AWS Transform comprehensive codebase analysis
    - Generate documentation in Documentation/ folder
```

### Phase 4: Post-Build
```yaml
post_build:
  commands:
    - Upload all generated files to S3
    - Exclude .git directory
```

## Data Flow

### 1. Build Trigger
```
User/CI Pipeline → aws codebuild start-build
├── Environment variables:
│   ├── REPOSITORY_URL (target repo)
│   ├── OUTPUT_BUCKET (S3 destination)
│   └── JOB_ID (unique identifier)
└── Returns build ID for monitoring
```

### 2. Repository Processing
```
CodeBuild → Git Clone → Local Storage
├── Clone repository to ./target-repo
├── Detect project type automatically
└── Prepare for AWS Transform analysis
```

### 3. Documentation Generation
```
AWS Transform CLI → Comprehensive Analysis → Documentation Output
├── Static code analysis
├── Architecture pattern detection
├── Dependency analysis
├── Security configuration review
├── Technical debt assessment
├── Operational procedure generation
└── Cross-referenced documentation
```

### 4. Result Delivery
```
Generated Docs → S3 Upload → Available for Download
├── Upload to s3://{bucket}/documentation/{job-id}/
├── Preserve directory structure
└── Accessible via AWS CLI or Console
```

## Generated Documentation Structure

AWS Transform creates comprehensive documentation:

```
Documentation/
├── README.md                    # Master navigation
├── architecture/
│   ├── overview.md             # System architecture
│   ├── components.md           # Component details
│   └── data-flow.md            # Data flow diagrams
├── reference/
│   ├── api.md                  # API documentation
│   └── configuration.md        # Config options
├── behavior/
│   └── workflows.md            # Behavioral analysis
├── analysis/
│   ├── code-metrics.md         # Code statistics
│   └── complexity-analysis.md  # Complexity scores
├── technical-debt/
│   └── technical-debt-report.md # Debt assessment
├── migration/
│   └── upgrade-guide.md        # Migration paths
└── diagrams/
    └── *.mermaid               # Visual diagrams
```

## Security Design

### IAM Permissions (Least Privilege)
- **CodeBuild Role**:
  - `transform-custom:*` - AWS Transform operations
  - `s3:*` on designated bucket - Documentation storage
  - `logs:*` - CloudWatch logging

### Network Security
- **CodeBuild**: Runs in AWS-managed VPC with internet access
- **S3 Bucket**: Private, no public access
- **Git Clone**: HTTPS only, public repositories

### Data Protection
- **Temporary Storage**: Build environment destroyed after completion
- **S3 Encryption**: Server-side encryption enabled
- **No Credentials**: Repository URLs must be public or use CodeBuild source credentials

## Scalability Considerations

### Concurrent Processing
- **CodeBuild**: Supports multiple concurrent builds
- **S3**: Handles high throughput for uploads
- **Independent Jobs**: Each build is isolated

### Resource Limits
- **Repository Size**: Limited by CodeBuild storage
- **Processing Time**: 60-minute timeout (configurable)
- **Memory**: 7 GB available for analysis

### Cost Optimization
- **On-Demand**: Pay only when generating documentation
- **No Idle Resources**: No persistent infrastructure
- **Efficient Processing**: Single build environment

## Monitoring and Observability

### CloudWatch Logs
- **Log Group**: `/aws/codebuild/aws-transform-doc-generator`
- **Log Stream**: One per build (build ID)
- **Content**: Full build output including Transform progress

### Build Status
```bash
# Check build status
aws codebuild batch-get-builds --ids <build-id> --region us-east-1

# Stream logs
aws logs tail /aws/codebuild/aws-transform-doc-generator --follow --region us-east-1
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Generate Documentation
  run: |
    aws codebuild start-build \
      --project-name aws-transform-doc-generator \
      --environment-variables-override \
        name=REPOSITORY_URL,value=${{ github.server_url }}/${{ github.repository }}
```

### AWS CodePipeline
```yaml
- aws codebuild start-build \
    --project-name aws-transform-doc-generator \
    --environment-variables-override \
      name=REPOSITORY_URL,value=$CODEBUILD_SOURCE_REPO_URL
```

## Extension Points

### Custom Analysis Context
- Modify buildspec to add `TRANSFORM_CONTEXT` environment variable
- Customize documentation focus (security, API, deployment)

### Output Formats
- Post-process markdown to HTML, PDF, or other formats
- Add custom templates for organization branding

### Notifications
- Add SNS notifications on build completion
- Integrate with Slack, Teams, or email

## Why CodeBuild?

This architecture uses CodeBuild for several reasons:

- **Simplicity**: No containers, no persistent infrastructure to manage
- **Cost-effective**: Pay only when generating documentation (~$0.35/job)
- **CI/CD native**: Easy integration with GitHub Actions, CodePipeline, GitLab CI
- **Auto-scaling**: CodeBuild handles concurrent builds automatically
- **Minimal maintenance**: AWS manages the build environment

This architecture provides a simple, cost-effective solution for automated documentation generation using AWS Transform's comprehensive codebase analysis capabilities.
