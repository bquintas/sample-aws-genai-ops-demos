#!/usr/bin/env python3
import aws_cdk as cdk
from stack import AnyCompanyITPortalStack

app = cdk.App()

AnyCompanyITPortalStack(
    app, 
    "AnyCompanyITPortalStack",
    description="Multi-portal IT demo environment for AI automation workflows (uksb-do9bhieqqh)(tag:it-portal-demo,operations-automation)",
    env=cdk.Environment(
        account=app.node.try_get_context("account"),
        region=app.node.try_get_context("region") or "us-east-1"
    )
)

app.synth()