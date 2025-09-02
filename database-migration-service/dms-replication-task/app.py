#!/usr/bin/env python3
import os
import aws_cdk as cdk
from dms.dms_stack import DmsStack
from settings import settings

from enums import Stage

app = cdk.App()
dms_stack = DmsStack(
    app, f"joget-{settings.service_name}-{settings.stage.value}-stack",
    env=cdk.Environment(account=settings.account, region=settings.region),
)

cdk.Tags.of(dms_stack).add("Environment", settings.stage.value)

app.synth()