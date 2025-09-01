output "alb_dns_name" {
  description = "ALB public DNS"
  value       = module.alb.alb_dns_name
}

output "artifact_bucket" {
  description = "S3 bucket for CodeDeploy artifacts"
  value       = module.codedeploy.artifact_bucket
}