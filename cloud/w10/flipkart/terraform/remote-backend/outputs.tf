# [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab
output "bucket_name" {
  description = "S3 bucket holding the remote state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.tfstate.arn
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.tflock.name
}

output "region" {
  value = var.aws_region
}

output "backend_hcl" {
  description = "Paste into terraform/providers.tf -> terraform { ... }, or save to backend.hcl and use `terraform init -backend-config=backend.hcl`."
  value = <<-EOT
    bucket         = "${aws_s3_bucket.tfstate.bucket}"
    key            = "${var.state_key}"
    region         = "${var.aws_region}"
    dynamodb_table = "${aws_dynamodb_table.tflock.name}"
    encrypt        = true
  EOT
}

output "backend_block" {
  description = "Drop-in HCL block for terraform/providers.tf"
  value       = <<-EOT
    backend "s3" {
      bucket         = "${aws_s3_bucket.tfstate.bucket}"
      key            = "${var.state_key}"
      region         = "${var.aws_region}"
      dynamodb_table = "${aws_dynamodb_table.tflock.name}"
      encrypt        = true
    }
  EOT
}
