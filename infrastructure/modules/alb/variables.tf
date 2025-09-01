variable "project_name" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "target_port" { type = number }
variable "enable_https" { type = bool }
variable "certificate_arn" { type = string }
variable "health_check_path" { type = string }