import aws_cdk as core
import aws_cdk.assertions as assertions

from dms_replication_instance.dms_replication_instance_stack import DmsReplicationInstanceStack

# example tests. To run these tests, uncomment this file along with the example
# resource in dms_replication_instance/dms_replication_instance_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = DmsReplicationInstanceStack(app, "dms-replication-instance")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
