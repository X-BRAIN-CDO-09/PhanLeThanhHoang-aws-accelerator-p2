<!-- [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab -->
# Remote state backend

Bootstraps the S3 bucket + DynamoDB lock table that the main `terraform/`
stack uses as its `backend "s3"`. Run **once** before the rest of the
foundation.

## What it creates

| Resource | Why |
|----------|-----|
| `aws_s3_bucket.tfstate` (versioned, SSE-S3, all public access blocked) | Stores `terraform.tfstate` |
| `aws_s3_bucket_lifecycle_configuration` | Expires noncurrent versions after 90 days |
| `aws_dynamodb_table.tflock` (PAY_PER_REQUEST, PITR on) | Holds the state lock so two `apply`s can't race |

Bucket name is `flipkart-tfstate-<8-hex>` so it's globally unique without a
guess.

## Apply

```bash
cd terraform/remote-backend
terraform init
terraform apply
```

Grab the two outputs you need:

```bash
terraform output -raw bucket_name
terraform output -raw lock_table_name
```

## Wire the main stack to it

Option A — paste the printed block into `terraform/providers.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "flipkart-tfstate-XXXXXXXX"
    key            = "w10/flipkart/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "flipkart-tflock"
    encrypt        = true
  }
}
```

Option B — keep `providers.tf` portable and pass via `-backend-config`:

```bash
terraform -chdir=../remote-backend output -raw backend_hcl > ../backend.hcl
cd ..
terraform init -backend-config=backend.hcl
```

## Migrating existing local state

If you've already run `terraform apply` against local state, migrate without
losing it:

```bash
cd ../          # main stack
terraform init -migrate-state
# Terraform prompts: "Do you want to copy existing state to the new backend?" → yes
```

## Tear-down

```bash
# Main stack first (so the lock table isn't in use):
terraform -chdir=../ destroy
# Then this:
terraform apply -var force_destroy=true   # only if you also want to wipe versions
terraform destroy
```

> ⚠ Don't `destroy` this while another collaborator still has state in the
> bucket. The bucket is versioned, but the DynamoDB table is not — losing it
> means losing the lock guarantee.
