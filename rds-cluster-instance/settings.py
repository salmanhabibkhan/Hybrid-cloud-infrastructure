from pydantic import Field, validator
from pydantic_settings import BaseSettings
from enums import Stage


class Settings(BaseSettings):
    """
    Usage:
        set -o allexport; source .env; set +o allexport
    """

    # General
    stage: Stage = Field(default="prod", env="STAGE")
    service_name: str = Field(default="Rds-cluster", env="SERVICE_NAME")

    # DB Engine
    db_engine: str = Field(default="aurora-postgresql", env="DB_ENGINE")

    # AWS Config
    region: str = Field(default="us-east-1", env="AWS_DEFAULT_REGION")
    account: str = Field(default="123456789012", env="CDK_DEFAULT_ACCOUNT")

    # VPC and Network
    vpc_id: str = Field(default="vpc-0a1b2c3d4e5f67890", env="VPC_ID")
    security_group_id: str = Field(default="sg-0a1b2c3d4e5f67890", env="SECURITY_GROUP_ID")
    db_subnet_group_name: str = Field(default="aurora-db-subnet-group", env="DB_SUBNET_GROUP_NAME")

    # Database Config
    db_name: str = Field(default="proddb", env="DB_NAME")
    db_username: str = Field(default="dbadmin", env="DB_USERNAME")
    db_password: str = Field(default="StrongPassword123!", env="DB_PASSWORD")
    instance_type: str = Field(default="t3.medium", env="INSTANCE_TYPE")
    engine_version: str = Field(default="13.7", env="ENGINE_VERSION")
    multi_az: bool = Field(default=True, env="MULTI_AZ")
    instance_count: int = Field(default=2, env="INSTANCE_COUNT")
    db_port: int = Field(default=5432, env="DB_PORT")

    # Backup & Maintenance
    backup_retention_days: int = Field(default=7, env="BACKUP_RETENTION_DAYS")
    preferred_backup_window: str = Field(default="03:00-04:00", env="PREFERRED_BACKUP_WINDOW")
    preferred_maintenance_window: str = Field(default="sun:04:00-sun:05:00", env="PREFERRED_MAINTENANCE_WINDOW")
    enable_backup_settings: bool = Field(default=True, env="ENABLE_BACKUP_SETTINGS")

    # Monitoring & Logs
    enable_cloudwatch_logs: bool = Field(default=True, env="ENABLE_CLOUDWATCH_LOGS")
    enable_enhanced_monitoring: bool = Field(default=True, env="ENABLE_ENHANCED_MONITORING")
    enable_performance_insights: bool = Field(default=True, env="ENABLE_PERFORMANCE_INSIGHTS")
    enable_devops_guru: bool = Field(default=False, env="ENABLE_DEVOPS_GURU")
    enable_babelfish: bool = Field(default=False, env="ENABLE_BABELFISH")

    # Protection & Public Access
    deletion_protection: bool = Field(default=True, env="DELETION_PROTECTION")
    public_access: bool = Field(default=False, env="PUBLIC_ACCESS")

    # Storage
    storage_type: str = Field(default="gp3", env="STORAGE_TYPE")
    storage_iops: int = Field(default=3000, env="STORAGE_IOPS")
    storage_encrypted: bool = Field(default=True, env="STORAGE_ENCRYPTED")

    # Environment
    environment: str = Field(default="dev", env="ENVIRONMENT")

    # Parameter Groups
    parameter_family: str = Field(default="aurora-postgresql13", env="PARAMETER_FAMILY")
    cluster_parameter_description: str = Field(default="Aurora cluster parameter group", env="CLUSTER_PARAMETER_DESCRIPTION")
    instance_parameter_description: str = Field(default="Aurora instance parameter group", env="INSTANCE_PARAMETER_DESCRIPTION")

    # Proxy
    proxy_family: str = Field(default="aurora-postgresql-proxy", env="PROXY_FAMILY")

    # Subnets
    subnet_1: str = Field(default="subnet-0a1b2c3d4e5f11111", env="SUBNET_1")
    subnet_2: str = Field(default="subnet-0a1b2c3d4e5f22222", env="SUBNET_2")
    subnet_3: str = Field(default="subnet-0a1b2c3d4e5f33333", env="SUBNET_3")
    subnet_4: str = Field(default="subnet-0a1b2c3d4e5f44444", env="SUBNET_4")
    subnet_5: str = Field(default="subnet-0a1b2c3d4e5f55555", env="SUBNET_5")
    subnet_6: str = Field(default="subnet-0a1b2c3d4e5f66666", env="SUBNET_6")

    # --- Validators ---
    @validator(
        "enable_cloudwatch_logs",
        "enable_enhanced_monitoring",
        "enable_performance_insights",
        "enable_devops_guru",
        "enable_babelfish",
        "deletion_protection",
        "public_access",
        "storage_encrypted",
        "enable_backup_settings",
        pre=True,
    )
    def parse_boolean(cls, v):
        if isinstance(v, str):
            return v.lower() == "true"
        return bool(v)

    @validator("multi_az", pre=True)
    def parse_multi_az(cls, v):
        if isinstance(v, str):
            return v.lower() == "true"
        return bool(v)


settings = Settings()

if __name__ == "__main__":
    print(settings.model_dump())