from aws_cdk import (
    aws_ec2 as ec2,
    aws_rds as rds,
    RemovalPolicy,
)
from constructs import Construct
from settings import settings

class VpcSetup(Construct):

    def __init__(self, scope: Construct, id: str) -> None:
        super().__init__(scope, id)

        # Import VPC from settings
        self.vpc = ec2.Vpc.from_lookup(self, "Vpc", vpc_id=settings.vpc_id)

        # Import Security Group
        self.security_group = ec2.SecurityGroup.from_security_group_id(self, "SecurityGroup", settings.security_group_id)

        # # Import DB Subnet Group
        self.db_subnet_group = rds.SubnetGroup.from_subnet_group_name(self, settings.db_subnet_group_name, subnet_group_name=settings.db_subnet_group_name)