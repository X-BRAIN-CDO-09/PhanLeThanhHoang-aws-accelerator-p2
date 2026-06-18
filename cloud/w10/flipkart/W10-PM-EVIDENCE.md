<!-- [w10-pm NEW] Created for w10_afternoon_secrets_supply_chain lab -->
# W10 Afternoon — Secrets + Supply Chain (Evidence Pack)

Carries the W9 GitOps/canary setup forward and adds:

- **W8 Foundation** (`terraform/`) — IaC for the Minikube node, ALB, IAM,
  AWS Secrets Manager secret used by ESO.
- **Lab 2.1 — ESO** (`k8s-eso/`, `backend/utils/dbCredentials.js`) — rotate the
  DB password in AWS Secrets Manager, see it inside the pod in < 60s, no
  restart.
- **Lab 2.2 — Trivy + Cosign + Sigstore Policy Controller**
  (`.github/workflows/build-scan-sign.yml`, `k8s-policy/`) — CI fails on
  HIGH/CRITICAL CVEs, signs images, cluster admission rejects anything
  unsigned.

```
flipkart/
├── terraform/                       # W8 Foundation (IaC)
├── argocd/apps/                     # W9 GitOps + new eso.yaml + policy.yaml
├── k8s/                             # W9 manifests (rollout now mounts the ESO secret)
├── k8s-eso/                         # Lab 2.1
├── k8s-policy/                      # Lab 2.2 (ClusterImagePolicy + tests/)
├── .github/workflows/               # Lab 2.2 CI
└── backend/                         # app.js / database.js read DB password from file
```

---

## 0. Bring up the platform (under 2h target)

```bash
# A. IaC — Minikube + ArgoCD + ESO + Policy Controller
cd terraform/remote-backend && terraform init && terraform apply
# paste the backend "s3" block into terraform/providers.tf
cd .. && terraform init -reconfigure && terraform apply \
  -var "db_initial_password=$(openssl rand -base64 24)"

# B. GitOps root — pulls argocd/apps/*.yaml
ssh -i flipkart-w10-key.pem ubuntu@$(terraform output -raw ec2_public_ip)
kubectl apply -f cloud/w10/flipkart/argocd/root.yaml

# (Update argocd/root.yaml `path` to cloud/w10/flipkart/argocd/apps once this
# branch is merged — currently still points at w9.)
```

---

## 1. Lab 2.1 — ESO rotation drill

### Setup (already encoded in Terraform + manifests)
- AWS Secrets Manager secret `prod/db/password` in `ap-southeast-1`.
- `k8s-eso/secret-store.yaml` uses the EC2 instance profile (no static creds).
- `k8s-eso/external-secret.yaml` syncs every **60 s** into K8s Secret
  `flipkart-db-password`.
- `k8s/backend/rollout.yaml` mounts that Secret at `/etc/flipkart/db/password`
  (no `subPath`, so kubelet hot-swaps the symlink on rotation).
- `backend/utils/dbCredentials.js` re-reads the file on every request.

### Rotation test

```bash
# 1) Observe current fingerprint from inside the running pod (no restart):
watch -n 2 curl -s http://<alb_dns>/api/v1/db-cred

# 2) Rotate in AWS:
aws secretsmanager put-secret-value \
  --region ap-southeast-1 \
  --secret-id prod/db/password \
  --secret-string "$(jq -n --arg p "$(openssl rand -base64 24)" '{password:$p}')"

# 3) Within ~60s, the `fingerprint` value changes WITHOUT a pod restart.
kubectl -n flipkart get pods -l app=flipkart-backend  # AGE unchanged
```

**Pass criterion:** new fingerprint visible in < 60 s, `RESTARTS` column is 0.

---

## 2. Lab 2.2 — Trivy + Cosign + Policy

### One-time key setup

```bash
# Local:
cosign generate-key-pair          # → cosign.key, cosign.pub
gh secret set COSIGN_PRIVATE_KEY < cosign.key
gh secret set COSIGN_PASSWORD --body "<the password you chose>"

# Commit ONLY the public key:
cp cosign.pub cloud/w10/flipkart/k8s-policy/cosign.pub

# Make sure k8s-policy/cosign-pub-secret.yaml is up to date:
kubectl create secret generic flipkart-cosign-pub \
  -n cosign-system \
  --from-file=cosign.pub=cloud/w10/flipkart/k8s-policy/cosign.pub \
  --dry-run=client -o yaml \
  > cloud/w10/flipkart/k8s-policy/cosign-pub-secret.yaml
git add cloud/w10/flipkart/k8s-policy/cosign.pub cloud/w10/flipkart/k8s-policy/cosign-pub-secret.yaml
git commit -m "lab2.2: pin cosign public key"
```

> ⚠ **Never** commit `cosign.key`. `.gitignore` already covers it.

### Verify the CI pipeline

Push any change under `cloud/w10/flipkart/backend/**`. The
`build-scan-sign.yml` workflow runs build → **Trivy HIGH/CRITICAL fail** →
push to GHCR → **Cosign sign by digest** → verify.

The step summary should show:

```
### backend image
- Image:  ghcr.io/<owner>/flipkart-backend:<sha>
- Digest: sha256:...
- Trivy:  no HIGH/CRITICAL
- Cosign: signed with COSIGN_PRIVATE_KEY
```

### Cluster admission tests

```bash
# Test 1 — unsigned, must be REJECTED:
kubectl apply -f k8s-policy/tests/test1-unsigned.yaml
# → admission webhook "policy.sigstore.dev" denied: no matching signatures

# Test 2 — signed by CI, must PASS:
IMAGE=$(gh run view --log -R <owner>/<repo> | grep -oE 'ghcr.io[^ ]+@sha256:[a-f0-9]+' | head -1)
sed "s|REPLACE_ME|$IMAGE|" k8s-policy/tests/test2-signed.yaml | kubectl apply -f -
kubectl -n flipkart get pod signed-backend -w
# → Running
```

---

## 3. How this stacks across W8 / W9 / W10

| Layer | Where | What it gives you |
|-------|-------|-------------------|
| W8 Foundation | `terraform/` | VPC SGs, ALB, Minikube node, ESO + Policy Controller installed via Helm in `init.sh` |
| W9 Delivery   | `argocd/`, `k8s/` | GitOps root, Argo Rollouts canary, kube-prometheus-stack |
| W10 Security  | `k8s-eso/`, `k8s-policy/`, `.github/workflows/` | Live secret rotation, fail-closed admission for unsigned images |

A clean run on a brand-new AWS account: roughly **20 min Terraform → 25 min
GitOps converge → 10 min CI build & sign → 10 min admission test = ~65 min**,
comfortably inside the 2-hour goal in the W10 summary.
