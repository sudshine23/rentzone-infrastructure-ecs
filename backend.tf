# store the terraform state file in s3 and lock with dynamodb
terraform {
  backend "s3" {
    bucket         = "sud009-terraform-remote-state"
    key            = "terraform-module/rentzone/terraform.tf"
    region         = "ap-south-1"
    profile        = "SUD"
    dynamodb_table = "terraform-state-lock"
  }
}