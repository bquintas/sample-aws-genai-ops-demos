# Architecture - Graviton Migration Assessment

## Overview

This demo implements automated Graviton migration assessment using AWS Transform's comprehensive codebase analysis capability with specialized Graviton migration context. The solution uses CodeBuild to process Git repositories and generate detailed migration assessments including cost analysis, compatibility evaluation, and implementation roadmaps.

All infrastructure is deployed via AWS CDK for consistent, repeatable deployments.

## Architecture Diagram

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Git Repo      │────▶│   CodeBuild      │────▶│   S3 Bucket     │
│   (any URL)     │     │   + AWS Transform│     │ (assessments)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  CloudWatch Logs │
                        │  (monitoring)    │
                        └──────────────────┘
```

## CDK Stack

The `GravitonAssessmentStack` deploys all required infrastructure:

```python
# infrastructure/cdk/stack.py
- S3 Bucket: graviton-assessment-{account}-{region}
- IAM Role: CodeBuildGravitonAssessmentRole
- CodeBuild Project: graviton-migration-assessor
```

## Components

### 1. CodeBuild Project
- **Name**: `graviton-migration-assessor`
- **Image**: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`
- **Compute**: `BUILD_GENERAL1_MEDIUM` (4 vCPU, 7 GB RAM)
- **Timeout**: 120 minutes
- **Key Functions**:
  - Clone Git repositories
  - Install AWS Transform CLI
  - Execute comprehensive codebase analysis with Graviton context
  - Upload migration assessments to S3

### 2. S3 Bucket

**Assessment Bucket** (`graviton-assessment-{account}-{region}`)
- **Purpose**: Store generated migration assessments and buildspec
- **Structure**:
  ```
  s3://graviton-assessment-{account}-{region}/
  ├── config/
  │   ├── buildspec.yml                    # Build specification
  │   └── graviton-context.md              # Graviton migration context
  └── assessments/
      └── {job-id}/                        # Generated assessments per job
          ├── Migration-Assessment/        # AWS Transform output
          ├── README.md
          └── ...
  ```
- **Access**: Private, accessed via IAM role

### 3. IAM Role

**CodeBuildGravitonAssessmentRole** (deployed via CDK)
- **Trust Policy**: CodeBuild service
- **Permissions** (least privilege via CDK grants):
  - S3 read/write on assessment bucket
  - CloudWatch Logs create/write for build logging
  - `transform-custom:*` for AWS Transform access

### 4. AWS Transform Integration
- **CLI**: Installed via `https://desktop-release.transform.us-east-1.api.aws/install.sh`
- **Transformation**: `AWS/early-access-comprehensive-codebase-analysis`
- **Execution**: `atx custom def exec -n "AWS/early-access-comprehensive-codebase-analysis" -p "." -x -t -d`
- **Context**: Custom Graviton migration guidance loaded from S3
- **Output**: Comprehensive Graviton migration assessment in markdown format

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
    - Download Graviton context from S3
    - Validate repository structure
```

### Phase 3: Build
```yaml
build:
  commands:
    - Run AWS Transform comprehensive analysis with Graviton context
    - Generate migration assessment in Migration-Assessment/ folder
```

### Phase 4: Post-Build
```yaml
post_build:
  commands:
    - Upload all generated files to S3
    - Exclude .git directory
```

## Data Flow

### 1. Assessment Trigger
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
├── Download Graviton context from S3
└── Prepare for AWS Transform analysis
```

### 3. Graviton Assessment Generation
```
AWS Transform CLI → Graviton Analysis → Migration Assessment
├── Architecture compatibility analysis
├── ARM64 vs x86_64 evaluation
├── Dependency compatibility matrix
├── Cost optimization calculations
├── Performance impact assessment
├── Migration complexity scoring
└── Implementation roadmap generation
```

### 4. Result Delivery
```
Generated Assessment → S3 Upload → Available for Download
├── Upload to s3://{bucket}/assessments/{job-id}/
├── Preserve directory structure
└── Accessible via AWS CLI or Console
```

## Generated Assessment Structure

AWS Transform creates comprehensive Graviton migration assessments:

```
Migration-Assessment/
├── README.md                           # Executive summary and navigation
├── architecture/
│   ├── compatibility-analysis.md      # Graviton compatibility assessment
│   ├── instance-mapping.md            # x86_64 to Graviton instance mapping
│   └── performance-considerations.md  # Performance impact analysis
├── cost-analysis/
│   ├── savings-calculation.md         # Cost savings projections
│   ├── tco-analysis.md               # Total Cost of Ownership
│   └── roi-timeline.md               # Return on Investment timeline
├── migration-plan/
│   ├── phased-approach.md            # Migration phases and priorities
│   ├── testing-strategy.md           # Validation and testing procedures
│   └── rollback-procedures.md        # Risk mitigation and rollback
├── technical-assessment/
│   ├── dependency-analysis.md        # Library and framework compatibility
│   ├── build-modifications.md        # Required build process changes
│   └── container-analysis.md         # Container and orchestration changes
├── implementation/
│   ├── quick-wins.md                 # Low-risk, high-impact opportunities
│   ├── pilot-candidates.md           # Recommended pilot workloads
│   └── resource-requirements.md      # Team and timeline estimates
└── appendix/
    ├── graviton-services.md          # AWS services supporting Graviton
    └── best-practices.md             # Graviton optimization best practices
```

## Security Design

### IAM Permissions (Least Privilege)
- **CodeBuild Role**:
  - `transform-custom:*` - AWS Transform operations
  - `s3:*` on designated bucket - Assessment storage
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
- **Independent Jobs**: Each assessment is isolated

### Resource Limits
- **Repository Size**: Limited by CodeBuild storage
- **Processing Time**: 120-minute timeout (configurable)
- **Memory**: 7 GB available for analysis

### Cost Optimization
- **On-Demand**: Pay only when generating assessments
- **No Idle Resources**: No persistent infrastructure
- **Efficient Processing**: Single build environment

## Monitoring and Observability

### CloudWatch Logs
- **Log Group**: `/aws/codebuild/graviton-migration-assessor`
- **Log Stream**: One per build (build ID)
- **Content**: Full build output including Transform progress

### Build Status
```bash
# Check build status
aws codebuild batch-get-builds --ids <build-id> --region us-east-1

# Stream logs
aws logs tail /aws/codebuild/graviton-migration-assessor --follow --region us-east-1
```

## CI/CD Integration

### GitHub Actions
```yaml
- name: Graviton Migration Assessment
  run: |
    aws codebuild start-build \
      --project-name graviton-migration-assessor \
      --environment-variables-override \
        name=REPOSITORY_URL,value=${{ github.server_url }}/${{ github.repository }}
```

### AWS CodePipeline
```yaml
- aws codebuild start-build \
    --project-name graviton-migration-assessor \
    --environment-variables-override \
      name=REPOSITORY_URL,value=$CODEBUILD_SOURCE_REPO_URL
```

## Extension Points

### Custom Assessment Context
- Modify `graviton-transformation/additional-plan-context.md` for specific focus areas
- Customize cost models for different regions or pricing models
- Add organization-specific migration criteria

### Output Formats
- Post-process markdown to HTML, PDF, or other formats
- Add custom templates for organization branding
- Generate executive summaries and technical deep-dives

### Notifications
- Add SNS notifications on assessment completion
- Integrate with Slack, Teams, or email for results delivery
- Create dashboards for migration progress tracking

## Graviton-Specific Analysis

### Architecture Compatibility
- **Compute Services**: EC2, ECS, EKS, Lambda ARM64 compatibility
- **Database Services**: RDS Graviton instance evaluation
- **Container Workloads**: ARM64 base image availability
- **Serverless Functions**: Lambda ARM64 migration opportunities

### Cost Modeling
- **Instance Pricing**: Graviton vs x86_64 cost comparison
- **Performance Ratios**: Price-performance optimization
- **Reserved Instances**: Graviton RI and Savings Plan benefits
- **Migration Costs**: One-time effort vs ongoing savings

### Migration Complexity Scoring
- **Low Complexity**: Stateless applications, standard libraries
- **Medium Complexity**: Custom dependencies, build modifications
- **High Complexity**: Architecture-specific code, legacy dependencies

## Why CodeBuild?

This architecture uses CodeBuild for several reasons:

- **Simplicity**: No containers, no persistent infrastructure to manage
- **Cost-effective**: Pay only when generating assessments (~$1.40-2.50/assessment)
- **CI/CD native**: Easy integration with GitHub Actions, CodePipeline, GitLab CI
- **Auto-scaling**: CodeBuild handles concurrent assessments automatically
- **Minimal maintenance**: AWS manages the build environment

## Why CDK?

Infrastructure is deployed via CDK for:

- **Consistency**: Repeatable deployments across environments
- **Version Control**: Infrastructure changes tracked in Git
- **Best Practices**: CDK applies security defaults (encryption, SSL enforcement)
- **Easy Cleanup**: Single `cdk destroy` removes all resources
- **Type Safety**: Python CDK provides IDE support and validation

## ROI Considerations

### Assessment Investment
- **One-time cost**: ~$1.40-2.50 per assessment
- **Time investment**: ~1 hour automated analysis
- **Resource requirement**: Minimal - fully automated

### Potential Returns
- **Typical Graviton savings**: 10-20% on compute costs
- **Large workload savings**: $10,000-100,000+ annually
- **Break-even timeline**: Days to weeks after migration
- **Assessment ROI**: 1000x+ return on assessment investment

This architecture provides a cost-effective, automated solution for Graviton migration assessment using AWS Transform's comprehensive codebase analysis capabilities with specialized Graviton migration context.