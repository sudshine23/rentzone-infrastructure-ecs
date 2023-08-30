# environment variables 
variable "region" {}
variable "project_name" {}
variable "environment" {}

variable "vpc_cidr" {}
variable "public_subnet_az1_cidr" {}
variable "public_subnet_az2_cidr" {}
variable "private_app_subnet_az1_cidr" {}
variable "private_app_subnet_az2_cidr" {}
variable "private_data_subnet_az1_cidr" {}
variable "private_data_subnet_az2_cidr" {}

# Security groups variable
variable "ssh_ip" {}

# rds variables
variable "database_snapshot_identifier" {}
variable "database_instance_class" {}
variable "database_instance_identifier" {}
variable "muti_az_deployment" {}

# alb variables
variable "target_type" {}

# s3 variables 
variable "env_file_bucket_name" {}
variable "env_file_name" {}

# ecs  variables 

variable "container_image" {}
variable "architecture" {}

# acm  variables 

variable "domain_name" {}
variable "alternative_names" {}

# route 53  variables 

variable "record_name" {}