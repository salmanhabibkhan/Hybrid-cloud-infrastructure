variable "project_name" {
  type    = string
  default = "hybrid-cloud-joget"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "salmanhabibkhan"
}

variable "region" {
  type    = string
  default = "us-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "admin_ip" {
  type        = string
  description = "Your public IP CIDR (e.g., 175.107.233.225/32)"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 2
}

variable "alb_enable_https" {
  type    = bool
  default = false
}

variable "alb_certificate_arn" {
  type    = string
  default = ""
}