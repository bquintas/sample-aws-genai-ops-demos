#!/usr/bin/env python3
"""CDK App for Graviton Migration Assessment Demo."""

import aws_cdk as cdk
from stack import GravitonAssessmentStack

app = cdk.App()

GravitonAssessmentStack(
    app,
    "GravitonAssessmentStack",
    description="Graviton migration assessment and cost optimization analysis (uksb-do9bhieqqh)(tag:graviton-migration,cost-optimization)",
)

app.synth()