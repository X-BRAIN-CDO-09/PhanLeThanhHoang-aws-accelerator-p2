<!-- [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab -->
# Flipkart W10 — Terraform foundation (W8 carry-over)

Provisions the **W8 Foundation** on AWS so the W9 GitOps stack and W10 security
labs can run on a fresh cluster end-to-end:

```
terraform/
├── remote-backend/    # S3 + DynamoDB for remote state (run once)
├── providers.tf       # AWS / TLS / HTTP providers + backend stub
├── variables.tf
├── main.tf            # network → compute → loadbalancing → secrets
├── outputs.tf
└── modules/
    ├── network/       # ALB-sg + EC2-sg
    ├── compute/       # Ubuntu + Minikube + ArgoCD + ESO + Policy Controller
    ├── loadbalancing/ # ALB → NodePort
    └── secrets/       # AWS Secrets Manager (prod/db/password) + IAM
```

## 1. Bootstrap remote state (once)

```bash
cd terraform/remote-backend
terraform init
terraform apply
# Copy the printed `backend "s3" { ... }` block into terraform/providers.tf
```

## 2. Apply the foundation

```bash
cd ../
terraform init -reconfigure
terraform apply \
  -var "db_initial_password=$(openssl rand -base64 24)"
```

Outputs you'll need later:

| Output           | Used by                                     |
| ---------------- | ------------------------------------------- |
| `alb_dns_name`   | Browse the Flipkart UI                      |
| `ec2_public_ip`  | `ssh -i flipkart-w10-key.pem ubuntu@<ip>`   |
| `db_secret_arn`  | ESO `SecretStore` / `ExternalSecret`        |
| `db_secret_name` | Same — referenced by name in `external-secret.yaml` |

## 3. Hand-off to GitOps

After `terraform apply` finishes, SSH to the node and apply the root ArgoCD
Application (`../argocd/root.yaml`). It picks up everything else:

```bash
ssh -i flipkart-w10-key.pem ubuntu@$(terraform output -raw ec2_public_ip)
kubectl apply -f https://raw.githubusercontent.com/.../cloud/w10/flipkart/argocd/root.yaml
```

Two-hour target: from `terraform apply` to a green canary deploy + signed image
pull + zero-downtime secret rotation should take **< 2h** on a clean account.

## Resource sizing — why t3.medium

W8's `counter-app` ran fine on `t3.small`. Flipkart runs MongoDB + Node backend +
NGINX frontend + ArgoCD + Prometheus stack + ESO + Policy Controller in the same
Minikube — `t3.small`'s 2 GB RAM will OOM. `t3.medium` (4 GB) is the minimum.
