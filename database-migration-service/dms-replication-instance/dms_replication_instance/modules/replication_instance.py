from aws_cdk import (
    Duration,
    Stack,
    aws_ec2 as ec2,
    aws_dms as dms
)
from settings import settings
from dms_replication_instance.modules.vpcsetup import lookup_vpc, lookup_security_group, lookup_subnet_group

def create_replication_instance(stack):
    vpc = lookup_vpc(stack)
    security_group = lookup_security_group(stack)
    subnet_group = lookup_subnet_group(stack)

    return dms.CfnReplicationInstance(
        stack, "ReplicationInstance",
        replication_instance_class=settings.replication_instance_class,
        allocated_storage=settings.allocated_storage,
        engine_version=settings.engine_version,
        replication_subnet_group_identifier=subnet_group.ref,
        vpc_security_group_ids=[security_group.security_group_id],
        publicly_accessible=settings.public_access,
        replication_instance_identifier=f"joget-{settings.service_name}-{settings.stage.value}-{settings.replication_instance_name}",
        resource_identifier=f"{settings.service_name}-{settings.stage.value}",
        multi_az=settings.multi_az,
        allow_major_version_upgrade=settings.allow_major_version_upgrade,
        auto_minor_version_upgrade=settings.auto_minor_version_upgrade,
        preferred_maintenance_window=settings.preferred_maintenance_window,
    )
