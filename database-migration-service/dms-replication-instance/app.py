#!/usr/bin/env python3
import os
import aws_cdk as cdk
from dms_replication_instance.dms_replication_instance_stack import DmsReplicationInstanceStack
from settings import settings

from enums import Stage

app = cdk.App()
dms_replication_instance = DmsReplicationInstanceStack(
    app, f"joget-{settings.service_name}-{settings.stage.value}-stack",
    env=cdk.Environment(account=settings.account, region=settings.region),
)

cdk.Tags.of(dms_replication_instance).add("Environment", settings.stage.value)

app.synth()