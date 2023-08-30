locals {
  region       = var.region
  project_name = var.project_name
  environment  = var.environment
}

# create vpc module
module "vpc" {
  source                       = "git@github.com:sudshine23/terraform-module-dynamic.git//vpc"
  region                       = local.region
  project_name                 = local.project_name
  environment                  = local.environment
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr
}

# create NAT Gateway
module "nat-gateway" {
  source                     = "git@github.com:sudshine23/terraform-module-dynamic.git//NatGateway"
  project_name               = local.project_name
  environment                = local.environment
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
}

# create security group 
module "security-group" {
  source       = "git@github.com:sudshine23/terraform-module-dynamic.git//security-groups"
  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
  ssh_ip       = var.ssh_ip
}

# create RDS instance
module "rds" {
  source                       = "git@github.com:sudshine23/terraform-module-dynamic.git//rds"
  project_name                 = local.project_name
  environment                  = local.environment
  private_data_subnet_az1_id   = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id   = module.vpc.private_data_subnet_az2_id
  database_snapshot_identifier = var.database_snapshot_identifier
  database_instance_class      = var.database_instance_class
  availability_zone_1          = module.vpc.availability_zone_1
  database_instance_identifier = var.database_instance_identifier
  muti_az_deployment           = var.muti_az_deployment
  database_security_group_id   = module.security-group.database_security_group_id
}

# ALB variables
module "alb" {
  source                = "git@github.com:sudshine23/terraform-module-dynamic.git//load-balancer"
  project_name          = local.project_name
  environment           = local.environment
  alb_security_group_id = module.security-group.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  target_type           = var.target_type
  vpc_id                = module.vpc.vpc_id
}

# S3 variables
module "s3" {
  source               = "git@github.com:sudshine23/terraform-module-dynamic.git//s3"
  project_name         = local.project_name
  env_file_bucket_name = var.env_file_bucket_name
  env_file_name        = var.env_file_name
}

# ecs task xecution role
module "ecs_task_execution_role" {
  source               = "git@github.com:sudshine23/terraform-module-dynamic.git//iam-role"
  project_name         = local.project_name
  environment          = local.environment
  env_file_bucket_name = module.s3.env_file_bucket_name
}

# create ecs cluster, task definition and service
module "ecs" {
  source = "git@github.com:sudshine23/terraform-module-dynamic.git//ecs"
  project_name = local.project_name
  environment = local.environment
  ecs_task_execution_role_arn = module.ecs_task_execution_role.ecs_task_execution_role_arn
  architecture = var.architecture
  container_image = var.container_image
  env_file_name = module.s3.env_file_name
  env_file_bucket_name = module.s3.env_file_bucket_name
  region = local.region
  private_app_subnet_az1_id = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id = module.vpc.private_app_subnet_az2_id
  app_server_security_group_id = module.security-group.app_server_security_group_id
  alb_target_group_arn = module.alb.alb_target_group_arn
}

# create  ecs  asg

module "asg" {
  source = "git@github.com:sudshine23/terraform-module-dynamic.git//asg-ecs"
  project_name = local.project_name
  environment = local.environment
  ecs_service = module.ecs.ecs_service
}

# create acm 
module "ssl_certificate" {
  source = "git@github.com:sudshine23/terraform-module-dynamic.git//acm"
  domain_name = var.domain_name
  alternative_names = var.alternative_names
}

# create route 53 record
 module "route-53" {
  source = "git@github.com:sudshine23/terraform-module-dynamic.git//route-53"
  domain_name = module.ssl_certificate.domain_name
  record_name = var.record_name
  application_load_balancer_dns_name = module.alb.application_load_balancer_dns_name
  application_load_balancer_zone_id = module.alb.application_load_balancer_zone_id
 }


# prints the website URL
output "website_url" {
  value = join("", ["https://", var.record_name, ".", var.domain_name])
}