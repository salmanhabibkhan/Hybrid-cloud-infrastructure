#!/usr/bin/env python3
import os
import aws_cdk as cdk
from rds_cluster_instance.rds_cluster_instance_stack import RdsClusterInstanceStack
from settings import settings

app = cdk.App()
rds_cluster_stack = RdsClusterInstanceStack(
    app, f"joget-{settings.service_name}-{settings.stage.value}-stack",
    env=cdk.Environment(account=settings.account, region=settings.region),
)

cdk.Tags.of(rds_cluster_stack).add("Environment", settings.stage.value)

app.synth()