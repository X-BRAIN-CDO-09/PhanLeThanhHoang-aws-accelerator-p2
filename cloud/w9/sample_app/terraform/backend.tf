terraform {
  backend "s3" {
    bucket         = "hoangplt-w9-terraform-state-bucket"
    key            = "w9/sample_app/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "hoangplt-w9-terraform-lock-table"
    encrypt        = true
  }
}
