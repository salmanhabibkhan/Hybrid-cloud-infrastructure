import aws_cdk as core
import aws_cdk.assertions as assertions

from rds_cluster_instance.rds_cluster_instance_stack import RdsClusterInstanceStack

# example tests. To run these tests, uncomment this file along with the example
# resource in rds_cluster_instance/rds_cluster_instance_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = RdsClusterInstanceStack(app, "rds-cluster-instance")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
