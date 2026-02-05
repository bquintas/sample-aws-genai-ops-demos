#!/usr/bin/env python3
import aws_cdk as cdk
from shared.utils import get_region
from stack import AnyCompanyITPortalStack

app = cdk.App()

# Get region using shared utility
region = get_region()

AnyCompanyITPortalStack(
    app, 
    f"AnyCompanyITPortalStack-{region}",
    description="Multi-portal IT demo environment for AI automation workflows (uksb-do9bhieqqh)(tag:it-portal-demo,operations-automation)",
    env=cdk.Environment(
        account=app.node.try_get_context("account"),
        region=region
    )
)

app.synth()