from aws_cdk import (
    Stack,
)
from constructs import Construct
from rds_cluster_instance.constructs.vpc_setup import VpcSetup
from rds_cluster_instance.constructs.rds_cluster import RdsCluster
from settings import settings

class RdsClusterInstanceStack(Stack):

    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Setup VPC
        vpc_setup = VpcSetup(self, "VpcSetup")

        # Setup RDS Cluster
        RdsCluster(
            self,
            " ",
            vpc=vpc_setup.vpc,
            security_group=vpc_setup.security_group,
            db_subnet_group=vpc_setup.db_subnet_group
        )
