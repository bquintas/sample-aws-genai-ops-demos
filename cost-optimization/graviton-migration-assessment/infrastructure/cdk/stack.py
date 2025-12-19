"""CDK Stack for Graviton Migration Assessment Demo.

This stack deploys:
- S3 bucket for assessment output and buildspec storage
- IAM role for CodeBuild with Transform, S3, and CloudWatch permissions
- CodeBuild project configured for AWS Transform Graviton migration analysis
"""

import aws_cdk as cdk
from aws_cdk import (
    Stack,
    aws_s3 as s3,
    aws_iam as iam,
    aws_codebuild as codebuild,
    RemovalPolicy,
    CfnOutput,
)
from constructs import Construct


class GravitonAssessmentStack(Stack):
    """Stack for Graviton Migration Assessment."""

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # S3 bucket for assessment output (let CDK generate unique name)
        output_bucket = s3.Bucket(
            self,
            "GravitonAssessmentBucket",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
            encryption=s3.BucketEncryption.S3_MANAGED,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
        )

        # IAM role for CodeBuild (let CDK generate unique name)
        codebuild_role = iam.Role(
            self,
            "CodeBuildGravitonAssessmentRole",
            assumed_by=iam.ServicePrincipal("codebuild.amazonaws.com"),
            description="IAM role for CodeBuild Graviton Migration Assessment",
        )

        # Grant S3 permissions
        output_bucket.grant_read_write(codebuild_role)

        # CloudWatch Logs permissions
        codebuild_role.add_to_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=[
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                ],
                resources=[
                    f"arn:aws:logs:{cdk.Aws.REGION}:{cdk.Aws.ACCOUNT_ID}:log-group:/aws/codebuild/*",
                ],
            )
        )

        # AWS Transform permissions
        codebuild_role.add_to_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=["transform-custom:*"],
                resources=["*"],
            )
        )

        # CodeBuild project (let CDK generate unique name)
        project = codebuild.Project(
            self,
            "GravitonMigrationAssessor",
            description="Graviton Migration Assessment - analyzes codebases for ARM64 migration opportunities and cost optimization",
            role=codebuild_role,
            timeout=cdk.Duration.minutes(120),
            environment=codebuild.BuildEnvironment(
                build_image=codebuild.LinuxBuildImage.AMAZON_LINUX_2_5,
                compute_type=codebuild.ComputeType.MEDIUM,
                environment_variables={
                    "REPOSITORY_URL": codebuild.BuildEnvironmentVariable(
                        value="https://github.com/aws/porting-advisor-for-graviton"
                    ),
                    "OUTPUT_BUCKET": codebuild.BuildEnvironmentVariable(
                        value=output_bucket.bucket_name
                    ),
                    "JOB_ID": codebuild.BuildEnvironmentVariable(
                        value="graviton-assessment-default"
                    ),
                },
            ),
            source=codebuild.Source.s3(
                bucket=output_bucket,
                path="config/buildspec.yml",
            ),
        )

        # Outputs
        CfnOutput(
            self,
            "OutputBucketName",
            value=output_bucket.bucket_name,
            description="S3 bucket for Graviton assessment output",
            export_name="GravitonAssessmentBucket",
        )

        CfnOutput(
            self,
            "CodeBuildProjectName",
            value=project.project_name,
            description="CodeBuild project name for Graviton assessment",
            export_name="GravitonAssessmentProjectName",
        )

        CfnOutput(
            self,
            "CodeBuildRoleArn",
            value=codebuild_role.role_arn,
            description="CodeBuild IAM role ARN",
            export_name="GravitonAssessmentRoleArn",
        )