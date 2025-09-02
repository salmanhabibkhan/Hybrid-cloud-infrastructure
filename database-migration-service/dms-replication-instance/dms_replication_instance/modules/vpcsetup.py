from aws_cdk import (
    Duration,
    Stack,
    aws_ec2 as ec2,
    aws_dms as dms
)
from settings import settings

def lookup_vpc(stack):
    return ec2.Vpc.from_lookup(stack, f"DMSVpc-{settings.vpc_id}", vpc_id=settings.vpc_id)

def lookup_security_group(stack):
    return ec2.SecurityGroup.from_security_group_id(
        stack, f"DMSSG-{settings.security_group_id}",
        security_group_id=settings.security_group_id
    )

def lookup_subnet_group(stack):
    return dms.CfnReplicationSubnetGroup(
        stack, f"DMS-SG-{settings.subnet_group_name}",
        replication_subnet_group_description=f"DMS:-{settings.subnet_group_discription}",
        subnet_ids=[
            settings.subnet_1,
            settings.subnet_2,
            settings.subnet_3,
            settings.subnet_4,
            settings.subnet_5,
            settings.subnet_6
        ],
        replication_subnet_group_identifier=f"joget-{settings.subnet_group_name}",
    )

