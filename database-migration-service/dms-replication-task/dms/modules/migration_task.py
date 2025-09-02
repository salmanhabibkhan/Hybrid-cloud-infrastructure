from aws_cdk import (
    Duration,
    Stack,
    aws_dms as dms
)
from settings import settings

def create_migration_task(scope, replication_instance_arn, source_endpoint_arn, target_endpoint_arn):
    return dms.CfnReplicationTask(
        scope, "DmsReplicationTask",
        migration_type=settings.migration_type,
        replication_instance_arn=replication_instance_arn,
        source_endpoint_arn=source_endpoint_arn,
        target_endpoint_arn=target_endpoint_arn,
        table_mappings=settings.table_mappings,
        replication_task_settings=settings.replication_task_settings,
        replication_task_identifier=f"joget-{settings.service_name}-{settings.stage.value}-{settings.replication_task_name}",
        resource_identifier=f"joget-{settings.service_name}-{settings.stage.value}-{settings.task_resource_identifier_name}",
    )
