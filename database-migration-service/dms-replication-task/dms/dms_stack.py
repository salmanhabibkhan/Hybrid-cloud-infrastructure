from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_dms as dms,
)
from constructs import Construct
from dms.modules.endpoints import create_source_endpoint, create_target_endpoint
from dms.modules.migration_task import create_migration_task
from settings import settings

class DmsStack(Stack):

    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Create Source and Target Endpoints
        source_endpoint = create_source_endpoint(self)
        target_endpoint = create_target_endpoint(self)

        # Create DMS Migration Task
        migration_task = create_migration_task(self, settings.replication_instance_arn, source_endpoint.ref, target_endpoint.ref)