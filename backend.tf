terraform {
  backend "s3" {
    bucket         = "terraform-vpc-remote-backend-bucket"
    key            = "vpc/env/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-vpc-state-lock-table"
  }
}