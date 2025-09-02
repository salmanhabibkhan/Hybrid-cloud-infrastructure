from aws_cdk import (
    # Duration,
    Stack,
    # aws_sqs as sqs,
)
from constructs import Construct
from dms_replication_instance.modules.replication_instance import create_replication_instance
from settings import settings

class DmsReplicationInstanceStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        create_replication_instance(self)


