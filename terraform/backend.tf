terraform {
  backend "s3" {
    key = "terraform/tfstate/state"
    bucket = "terraform-state-28a8ff"
    region = "us-east-1"
  }
}