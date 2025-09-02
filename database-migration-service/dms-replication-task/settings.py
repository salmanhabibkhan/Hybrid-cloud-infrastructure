import json
from pydantic import BaseModel, Field, validator
from pydantic_settings import BaseSettings
from pathlib import Path

from enums import Stage

class Settings(BaseSettings):
    """
    set -o allexport; source .env; set +o allexport
    """
    stage: Stage = Field(env='STAGE', default='dev')
    service_name: str = Field(env='SERVICE_NAME', default='dms')

    region: str = Field(env='AWS_DEFAULT_REGION', default='us-east-1')
    account: str = Field(env='CDK_DEFAULT_ACCOUNT', default='014648506868')

    endpoint_engin_name: str = Field(..., env='ENDPOINT_ENGIN_NAME')

    source_db_username: str = Field(..., env='SOURCE_DB_USERNAME')
    source_db_password: str = Field(..., env='SOURCE_DB_PASSWORD')
    source_db_server_name: str = Field(..., env='SOURCE_DB_SERVER_NAME')
    source_db_port: int = Field(..., env='SOURCE_DB_PORT')
    source_db_name: str = Field(..., env='SOURCE_DB_NAME')
    source_endpoint_name: str = Field(..., env='SOURCE_ENDPOINT_NAME')

    target_db_username: str = Field(..., env='TARGET_DB_USERNAME')
    target_db_password: str = Field(..., env='TARGET_DB_PASSWORD')
    target_db_server_name: str = Field(..., env='TARGET_DB_SERVER_NAME')
    target_db_port: int = Field(..., env='TARGET_DB_PORT')
    target_db_name: str = Field(..., env='TARGET_DB_NAME')
    target_endpoint_name: str = Field(..., env='TARGET_ENDPOINT_NAME')

    replication_instance_arn: str = Field(..., env='REPLICATION_INSTANCE_ARN')

    replication_task_name: str = Field(...,env='REPLICATION_TASK_NAME')
    task_resource_identifier_name: str = Field(..., env='TASK_RESOURCE_IDENTIFIER_NAME')

    migration_type: str = Field(..., env='MIGRATION_TYPE')

    # Variables for JSON structures

    schema_name: str = Field(..., env='SCHEMA_NAME')
    table_name: str = Field(..., env='TABLE_NAME')
    rule_id: str = Field(..., env='RULE_ID')
    rule_name: str = Field(..., env='RULE_NAME')

    target_schema: str = Field(..., env='TARGET_SCHEMA')
    support_lobs: bool = Field(..., env='SUPPORT_LOBS')
    full_lob_mode: bool = Field(..., env='FULL_LOB_MODE')
    lob_chunk_size: int = Field(..., env='LOB_CHUNK_SIZE')
    limited_size_lob_mode: bool = Field(..., env='LIMITED_SIZE_LOB_MODE')
    lob_max_size: int = Field(..., env='LOB_MAX_SIZE')
    inline_lob_max_size: int = Field(..., env='INLINE_LOB_MAX_SIZE')
    load_max_file_size: int = Field(..., env='LOAD_MAX_FILE_SIZE')
    parallel_load_threads: int = Field(..., env='PARALLEL_LOAD_THREADS')
    parallel_load_buffer_size: int = Field(..., env='PARALLEL_LOAD_BUFFER_SIZE')

    schema_name_mapping: str = Field(..., env='SCHEMA_NAME_MAPPING')

    # Load table mappings from external JSON file and replace the schema name placeholder
    table_mappings_file: str = Field(env='TABLE_MAPPINGS_FILE')

    @property
    def table_mappings(self) -> str:
        with open(self.table_mappings_file, 'r') as f:
            table_mappings_dict = json.load(f)
        
        # Replace the placeholder with the actual schema name
        table_mappings_dict["rules"][0]["object-locator"]["schema-name"] = self.schema_name_mapping
        
        return json.dumps(table_mappings_dict)

    json_file_path: str = Field(env='JSON_FILE_PATH')

    @property
    def replication_task_settings(self) -> str:
        # Load the JSON file
        with open(self.json_file_path, 'r') as file:
            replication_task_settings_dict = json.load(file)
        
        # Modify the dictionary if needed, e.g., replace empty strings with environment variables
        replication_task_settings_dict["TargetMetadata"]["TargetSchema"] = self.target_schema
        
        return json.dumps(replication_task_settings_dict, indent=2)
    
    class Config:
        env_file = ".env"

settings = Settings()

print(settings)