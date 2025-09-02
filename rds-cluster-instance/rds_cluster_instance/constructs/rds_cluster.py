from aws_cdk import (
    aws_rds as rds,
    aws_ec2 as ec2,
    aws_logs as logs,
    aws_iam as iam,
    aws_secretsmanager as secretsmanager,
    RemovalPolicy,
    Duration
)
from constructs import Construct
from settings import settings
from rds_cluster_instance.constructs.rds_resources import create_db_secret, create_rds_proxy_role
from enums import Stage

class RdsCluster(Construct):
    service_name: str
    stage: Stage
    stack_prefix: str

    def __init__(
            self, scope: Construct, id: str, 
            vpc: ec2.IVpc, security_group: ec2.ISecurityGroup, db_subnet_group: rds.ISubnetGroup,
            service_name=settings.service_name,
            stage=Stage(settings.stage),
    ) -> None:
        super().__init__(scope, id)
        
        self.service_name = service_name
        self.stage = stage
        self.stack_prefix = f'{self.service_name}-{self.stage.value}'

        # Engine version for Aurora PostgreSQL
        engine_version = settings.engine_version  # Update this version if needed

        # Create parameter groups for cluster
        cluster_parameter_group = rds.CfnDBClusterParameterGroup(self, "joget-cluster-parameter-group",
            description=settings.cluster_parameter_description,
            family=settings.parameter_family,  # Replace with the appropriate family for your engine version
            parameters={
                    "rds.force_ssl": "0",
            },
            db_cluster_parameter_group_name=f'joget-{self.stack_prefix}-parameter-group',  # Specify your custom name here
        )
        
        # Create parameter groups for Instance
        instance_parameter_group = rds.CfnDBParameterGroup(self, "joget-instance-parameter-group",
            description=settings.instance_parameter_description,
            family=settings.parameter_family,  # Replace with the appropriate family for your engine version
            parameters={
                "max_connections": "5000",
            },
            db_parameter_group_name=f'joget-{self.stack_prefix}-instance-parameter-group',  # Specify your custom name here
        )

        # Create CloudWatch Logs if enabled
        log_group = logs.LogGroup(
            self,
            "RDSLogGroup",
            retention=logs.RetentionDays.ONE_MONTH,
            removal_policy=RemovalPolicy.DESTROY,
            log_group_name=f'joget-{self.stack_prefix}-cloudwatch-logs',
        ) if settings.enable_cloudwatch_logs else None
        
        # Create Secrets Manager secret and IAM role using imported functions
        secret = create_db_secret(self)
        proxy_role = create_rds_proxy_role(self)


        # Create the Aurora PostgreSQL cluster
        db_cluster = rds.CfnDBCluster(
            self,
            "JogetDBCluster",
            engine="aurora-postgresql",
            engine_version=engine_version,
            master_username=settings.db_username,
            master_user_password=settings.db_password,
            db_subnet_group_name=db_subnet_group.subnet_group_name,
            vpc_security_group_ids=[security_group.security_group_id],
            db_cluster_parameter_group_name=cluster_parameter_group.db_cluster_parameter_group_name,
            port=settings.db_port,
            backup_retention_period=settings.backup_retention_days if settings.enable_backup_settings else None,
            preferred_backup_window=settings.preferred_backup_window if settings.enable_backup_settings else None,
            preferred_maintenance_window=settings.preferred_maintenance_window if settings.enable_backup_settings else None,
            storage_encrypted=settings.storage_encrypted,
            deletion_protection=settings.deletion_protection,
            db_cluster_identifier=f'joget-{self.stack_prefix}',
            availability_zones=["us-east-1a", "us-east-1c", "us-east-1b"],  # Specify valid AZs here
            enable_cloudwatch_logs_exports=["postgresql"] if settings.enable_cloudwatch_logs else [],
        )

        # Create the writer instance in the cluster
        db_instance_writer = rds.CfnDBInstance(
            self,
            "JogetDBInstanceWriter",
            db_instance_identifier=f'joget-{self.stack_prefix}-instance1',
            db_instance_class=settings.instance_type,  # Instance type
            engine=settings.db_engine,
            db_cluster_identifier=db_cluster.ref,
            publicly_accessible=settings.public_access,
            db_parameter_group_name=instance_parameter_group.db_parameter_group_name,
            enable_performance_insights=settings.enable_performance_insights,
        )

        # Conditionally create the reader instance if multi_az is enabled
        if settings.multi_az:
            db_instance_reader = rds.CfnDBInstance(
                self,
                "JogetDBInstanceReader",
                db_instance_identifier=f'joget-{self.stack_prefix}-instance2',
                db_instance_class=settings.instance_type,  # Instance type
                engine=settings.db_engine,
                db_cluster_identifier=db_cluster.ref,
                publicly_accessible=settings.public_access,
                db_parameter_group_name=instance_parameter_group.db_parameter_group_name,
                enable_performance_insights=settings.enable_performance_insights,
            )
            
        
        rds_proxy = rds.CfnDBProxy(
            self,
            "JogetDBProxy",
            auth=[rds.CfnDBProxy.AuthFormatProperty(
                auth_scheme="SECRETS",
                description="Auth for RDS Proxy",
                secret_arn=secret.secret_arn,
                iam_auth="DISABLED"
            )],
            db_proxy_name=f'joget-{self.stack_prefix}-proxy-bmw',
            vpc_security_group_ids=[security_group.security_group_id],
            vpc_subnet_ids=[
                settings.subnet_1,
                settings.subnet_2,
                settings.subnet_3,
                settings.subnet_4,
                settings.subnet_5,
                settings.subnet_6
            ],     # Use the subnets from your existing subnet group
            role_arn=proxy_role.role_arn, # ARN of the IAM role for the RDS Proxy
            idle_client_timeout=Duration.minutes(30).to_seconds(), # Adjust as needed
            require_tls=False,
            debug_logging=False,
            engine_family=settings.proxy_family
        )