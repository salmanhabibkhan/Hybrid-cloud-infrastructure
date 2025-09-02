from aws_cdk import (
    Stack,
    aws_dms as dms,
)
import aws_cdk.assertions as assertions
from dms.dms_stack import DmsStack


def test_sqs_queue_created():
    app = App()
    stack = DmsStack(app, "dms")
    template = assertions.Template.from_stack(stack)

