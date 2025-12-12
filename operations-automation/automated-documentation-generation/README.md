# Automated Documentation Generation

Automatically generate comprehensive technical documentation from any codebase using AWS Transform's `AWS/early-access-comprehensive-codebase-analysis` transformation in a simple CodeBuild project.

## Important: Processing Time

The comprehensive codebase analysis typically takes **45-60 minutes** to complete, regardless of repository size. This is due to the deep AI-powered analysis that generates architecture diagrams, behavior documentation, migration guides, and technical debt reports. Plan accordingly when integrating into CI/CD pipelines.

## What This Demo Shows

This demo provides a **CodeBuild-based AWS Transform solution** that generates comprehensive documentation from any Git repository. Simple to deploy, easy to integrate into CI/CD pipelines.

## Generated Documentation Includes

- **System Architecture**: Component relationships, data flows, technology stack analysis
- **Technical Specifications**: Code structure, API endpoints, configuration details  
- **Operational Runbooks**: Deployment procedures, monitoring guides, troubleshooting
- **Security Analysis**: Best practices, vulnerability identification, compliance mapping
- **Technical Debt Analysis**: Actionable insights on outdated components and maintenance needs

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Git Repo      │────▶│   CodeBuild      │────▶│   S3 Bucket     │
│   (any URL)     │     │   + AWS Transform│     │   (docs output) │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

**Components:**
- **CodeBuild Project**: Runs AWS Transform CLI in a managed build environment
- **S3 Bucket**: Stores generated documentation
- **IAM Role**: Minimal permissions for Transform, S3, and CloudWatch

## Prerequisites

- AWS CLI version 2.31.13 or later (includes AWS Transform CLI)
- PowerShell (Windows) or Bash (Linux/macOS)
- AWS credentials configured with appropriate permissions

### Required AWS Permissions

- CodeBuild (create projects, start builds)
- S3 (create buckets, read/write objects)
- IAM (create roles and policies)
- CloudWatch Logs (create log groups, write logs)
- AWS Transform (`transform-custom:*` permissions)

## Quick Start

### Deploy with Your Repository

```powershell
# PowerShell (Windows)
cd operations-automation/automated-documentation-generation
.\generate-docs.ps1 -RepositoryUrl "https://github.com/owner/repo"
```

```bash
# Bash (Linux/macOS)
cd operations-automation/automated-documentation-generation
./generate-docs.sh -r "https://github.com/owner/repo"
```

### Deploy with Default Sample Repository

If you don't specify a repository URL, the script uses a default sample repository for testing:

```powershell
# PowerShell - uses default sample repo
.\generate-docs.ps1
```

```bash
# Bash - uses default sample repo
./generate-docs.sh
```

The script will:
1. Validate AWS credentials and CLI version
2. Create S3 bucket for documentation output
3. Create IAM role with required permissions
4. Create CodeBuild project
5. Start a build with the specified (or default) repository

## Usage

### Generate Documentation for Any Repository

```bash
# Start a documentation generation job
aws codebuild start-build \
  --project-name aws-transform-doc-generator \
  --region us-east-1 \
  --environment-variables-override \
    name=REPOSITORY_URL,value=https://github.com/owner/repo \
    name=JOB_ID,value=my-job-123
```

### Monitor Build Progress

```bash
# Check build status
aws codebuild batch-get-builds --region us-east-1 --ids <build-id>

# Stream build logs
aws logs tail /aws/codebuild/aws-transform-doc-generator --follow --region us-east-1
```

### Retrieve Generated Documentation

The deployment script offers to wait for the build to complete and automatically download the documentation to your local machine. If you choose not to wait, you can download manually:

```bash
# List generated documentation
aws s3 ls s3://doc-gen-output-<account-id>-<region>/documentation/ --recursive

# Download documentation to local folder
aws s3 cp s3://doc-gen-output-<account-id>-<region>/documentation/<job-id>/ ./generated-docs --recursive
```

The downloaded documentation will be in a `generated-docs-<job-id>` folder in your current directory.

## Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `REPOSITORY_URL` | ✅ | Git repository URL to analyze | Serverless Digital Asset Payments sample |
| `OUTPUT_BUCKET` | ✅ | S3 bucket for documentation | Auto-created |
| `JOB_ID` | ❌ | Unique job identifier | `doc-gen-<timestamp>` |

## CI/CD Integration Examples

### GitHub Actions

```yaml
name: Generate Documentation
on:
  push:
    branches: [main]

jobs:
  documentation:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-region: us-east-1
          
      - name: Generate Documentation
        run: |
          aws codebuild start-build \
            --project-name aws-transform-doc-generator \
            --region us-east-1 \
            --environment-variables-override \
              name=REPOSITORY_URL,value=${{ github.server_url }}/${{ github.repository }} \
              name=JOB_ID,value=${{ github.run_id }}
```

### AWS CodePipeline

```yaml
version: 0.2
phases:
  build:
    commands:
      - |
        aws codebuild start-build \
          --project-name aws-transform-doc-generator \
          --region us-east-1 \
          --environment-variables-override \
            name=REPOSITORY_URL,value=$CODEBUILD_SOURCE_REPO_URL \
            name=JOB_ID,value=$CODEBUILD_BUILD_ID
```

### GitLab CI

```yaml
generate_docs:
  stage: build
  script:
    - |
      aws codebuild start-build \
        --project-name aws-transform-doc-generator \
        --region us-east-1 \
        --environment-variables-override \
          name=REPOSITORY_URL,value=$CI_REPOSITORY_URL \
          name=JOB_ID,value=$CI_PIPELINE_ID
```

## Cost Estimates

### AWS Transform Custom Pricing

AWS Transform custom charges per **agent minute** at **$0.035/minute**. Agent minutes are only counted when the agent is actively working (planning, reasoning, analyzing, modifying code), not during builds or idle time.

### Per Documentation Job (Estimated)
- **CodeBuild** (BUILD_GENERAL1_MEDIUM, ~50 min): ~$0.33
- **AWS Transform analysis** (~30-60 agent min): ~$1.05 - $2.10
- **S3 storage** (100MB documentation): ~$0.002
- **Total per job**: ~$1.40 - $2.50

### Monthly Estimates

| Usage Level | Jobs/Month | Estimated Cost |
|-------------|------------|----------------|
| Light | 10 | ~$15-25/month |
| Medium | 50 | ~$70-125/month |
| Production | 100 | ~$140-250/month |

### Cost Optimization Tips
- Use AWS Budgets to set limits on agent minutes
- Set up S3 lifecycle policies to archive old documentation
- Test on representative repos first to establish baseline costs

**Note**: Costs vary by codebase complexity. The same transformation can cost different amounts on different codebases.

## AWS Transform CLI Options

The transformation uses `atx custom def exec` with these available flags:

| Flag | Description | Used |
|------|-------------|------|
| `-x` / `--non-interactive` | No user prompts | ✅ |
| `-t` / `--trust-all-tools` | Auto-trust all tools | ✅ |
| `-d` / `--do-not-learn` | Skip knowledge extraction (faster) | ✅ |
| `-g` / `--configuration` | Config file (YAML/JSON) | ❌ |
| `--tv` / `--transformation-version` | Use specific version | ❌ |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `ATX_SHELL_TIMEOUT` | Override shell timeout (default 900s) |
| `ATX_DISABLE_UPDATE_CHECK` | Skip update checks at startup |

### Performance Notes

The **45-60 minute runtime** is inherent to comprehensive AI analysis. The transformation performs:
- Deep code structure analysis
- Architecture diagram generation
- Behavior documentation
- Migration guide creation
- Technical debt analysis

**There is no "fast mode"** - this is the nature of comprehensive AI-powered analysis. The wall-clock time includes both agent processing and local operations.

### Tips for Development/Testing

1. **Use smaller test repos** during development/testing
2. **Add `-d` flag** to skip knowledge extraction (already enabled)
3. **Set `ATX_DISABLE_UPDATE_CHECK=true`** to skip update checks
4. **Plan for async workflows** - trigger builds and check results later

## Buildspec Configuration

The CodeBuild project uses a buildspec stored in S3. Key phases:

```yaml
phases:
  install:
    # Install AWS Transform CLI and dependencies
    
  pre_build:
    # Clone target repository
    
  build:
    # Run AWS Transform comprehensive codebase analysis
    # Uses: atx custom def exec -n "..." -p "." -x -t -d
    
  post_build:
    # Upload generated documentation to S3
```

See `buildspec.yml` for the complete configuration.

## Troubleshooting

### Build Fails During Install Phase
- Ensure AWS CLI version 2.31.13+ is available
- Check that the CodeBuild service role has internet access

### AWS Transform Analysis Fails
- Verify the repository URL is publicly accessible
- Check CloudWatch logs for detailed error messages
- Some project types may not be fully supported

### Documentation Not Appearing in S3
- Verify the S3 bucket exists and IAM role has write permissions
- Check the post_build phase logs for upload errors

### Debugging Commands

```bash
# View detailed build logs
aws logs get-log-events \
  --log-group-name /aws/codebuild/aws-transform-doc-generator \
  --log-stream-name <build-id> \
  --region us-east-1

# Check IAM role permissions
aws iam get-role --role-name CodeBuildDocGenRole
aws iam list-attached-role-policies --role-name CodeBuildDocGenRole
```

## Cleanup

Remove all resources:

```powershell
# Delete CodeBuild project
aws codebuild delete-project --name aws-transform-doc-generator --region us-east-1

# Delete IAM role (detach policies first)
aws iam detach-role-policy --role-name CodeBuildDocGenRole --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
aws iam detach-role-policy --role-name CodeBuildDocGenRole --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam delete-role-policy --role-name CodeBuildDocGenRole --policy-name TransformCustomPolicy
aws iam delete-role --role-name CodeBuildDocGenRole

# Delete S3 bucket (empty first)
aws s3 rm s3://doc-gen-output-<account-id>-<region> --recursive
aws s3api delete-bucket --bucket doc-gen-output-<account-id>-<region>
```

## Files

| File | Description |
|------|-------------|
| `generate-docs.ps1` | PowerShell deployment script |
| `generate-docs.sh` | Bash deployment script |
| `buildspec.yml` | CodeBuild build specification |
| `ARCHITECTURE.md` | Technical architecture details |
