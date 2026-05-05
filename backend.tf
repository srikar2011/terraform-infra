terraform {
  backend "s3" {
    bucket         = "terraform-state-364829013514"
    key            = "mywebapp/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}