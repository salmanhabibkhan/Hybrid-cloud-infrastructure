from aws_cdk import (
    aws_iam as iam,
    aws_secretsmanager as secretsmanager,
)
from constructs import Construct
from settings import settings

def create_rds_proxy_role(scope: Construct) -> iam.Role:
    """
    Creates an IAM role for RDS Proxy.
    """
def create_rds_proxy_role(scope: Construct) -> iam.Role:
    """
    Creates an IAM role for RDS Proxy with a custom policy.
    """
    role = iam.Role(
        scope,
        "RdsProxyRole",
        assumed_by=iam.ServicePrincipal("rds.amazonaws.com"),
    )
    
    # Add additional permissions if necessary
    role.add_to_policy(
        iam.PolicyStatement(
            actions=[
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            resources=["*"]
        )
    )
    
    return role

def create_db_secret(scope: Construct) -> secretsmanager.CfnSecret:
    """
    Creates a Secrets Manager secret for RDS credentials use for RDS proxy.
    """
    secret = secretsmanager.Secret(
        scope,
        "DBSecret",
        secret_name=f'joget-{settings.service_name}-{settings.stage.value}-secret-manager',
        description="Database credentials for RDS",
        generate_secret_string=secretsmanager.SecretStringGenerator(
                secret_string_template='{"username": "postgres"}',
                generate_string_key=settings.db_password,
                exclude_characters="\"@/\\",
                password_length=16
            )
    )
    return secret
