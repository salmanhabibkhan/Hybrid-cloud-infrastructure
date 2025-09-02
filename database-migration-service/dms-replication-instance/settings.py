from pydantic import BaseModel, Field, validator
from pydantic_settings import BaseSettings

from enums import Stage

class Settings(BaseSettings):
    """
    set -o allexport; source .env; set +o allexport
    """
    stage: Stage = Field(env='STAGE')
    service_name: str = Field(env='SERVICE_NAME')

    region: str = Field(env='AWS_DEFAULT_REGION')
    account: str = Field(env='CDK_DEFAULT_ACCOUNT')

    vpc_id: str = Field(..., env='VPC_ID')
    subnet_group_name: str = Field(..., env='SUBNET_GROUP_NAME')
    subnet_group_discription: str = Field(..., env='SUBNET_GROUP_DISCRIPTION')
    security_group_id: str = Field(..., env='SECURITY_GROUP_ID')

    replication_instance_class: str = Field(..., env='REPLICATION_INSTANCE_CLASS')
    replication_instance_name: str = Field(..., env='REPLICATION_INSTANCE_NAME')
    allocated_storage: int = Field(..., env='ALLOCATED_STORAGE')
    engine_version: str = Field(..., env='ENGINE_VERSION')
    multi_az: bool = Field(..., env='MULTI_AZ')
    public_access: bool = Field(..., env='PUBLIC_ACCESS')
    
    allow_major_version_upgrade: bool = Field(..., env='ALLOW_MAJOR_VERSION_UPGRADE')
    auto_minor_version_upgrade: bool = Field(..., env='AUTO_MINOR_VERSION_UPGRADE')
    preferred_maintenance_window: str = Field(..., env='PREFERRED_MAINTENANCE_WINDOW')
    availability_zone: str = Field(..., env='AVAILABILITY_ZONE')
    
    subnet_1: str = Field(..., env='SUBNET_1')
    subnet_2: str = Field(..., env='SUBNET_2')
    subnet_3: str = Field(..., env='SUBNET_3')
    subnet_4: str = Field(..., env='SUBNET_4')
    subnet_5: str = Field(..., env='SUBNET_5')
    subnet_6: str = Field(..., env='SUBNET_6')


    @validator('multi_az', pre=True)
    def parse_multi_az(cls, v):
        if isinstance(v, str):
            return v.lower() == 'true'
        return bool(v) 

    @validator('public_access','allow_major_version_upgrade', 'auto_minor_version_upgrade', pre=True)
    def parse_boolean(cls, v):
        if isinstance(v, str):
            return v.lower() == 'true'
        return bool(v)       

    class Config:
        env_file = ".env"

settings = Settings()

print(settings)