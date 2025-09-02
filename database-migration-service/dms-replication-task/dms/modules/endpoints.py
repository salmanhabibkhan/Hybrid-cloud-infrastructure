from aws_cdk import (
    Stack,
    aws_dms as dms
)
from settings import settings

def create_source_endpoint(stack):
    return dms.CfnEndpoint(
        stack, "SourceEndpoint",
        endpoint_type="source",
        engine_name=settings.endpoint_engin_name,
        username=settings.source_db_username,
        password=settings.source_db_password,
        server_name=settings.source_db_server_name,
        port=settings.source_db_port,
        database_name=settings.source_db_name,
        endpoint_identifier=f"joget-{settings.service_name}-{settings.stage.value}-{settings.source_endpoint_name}",
    )

def create_target_endpoint(stack):
    return dms.CfnEndpoint(
        stack, "TargetEndpoint",
        endpoint_type="target",
        engine_name=settings.endpoint_engin_name,
        username=settings.target_db_username,
        password=settings.target_db_password,
        server_name=settings.target_db_server_name,
        port=settings.target_db_port,
        database_name=settings.target_db_name,
        endpoint_identifier=f"joget-{settings.service_name}-{settings.stage.value}-{settings.target_endpoint_name}",
    )
