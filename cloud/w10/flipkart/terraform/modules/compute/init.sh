#!/bin/bash
# [w10-pm UPDATED] Full W9 stack bootstrap on t3.xlarge
# Phase 1+2: Minikube sizing + ArgoCD app-of-apps auto-bootstrap
set -euxo pipefail

# Bootstrap a Minikube node ready to receive the W9 GitOps + W10 security stack.
# After this script finishes the node has: docker, kubectl, helm, minikube,
# ArgoCD, External Secrets Operator, Sigstore Policy Controller,
# kube-prometheus-stack, Argo Rollouts, and the full MERN app.
# All services are tunneled via socat for ALB/SSH access.

export DEBIAN_FRONTEND=noninteractive

###############################################################################
# 1. Base packages
###############################################################################
apt-get update -y
apt-get install -y docker.io socat conntrack curl unzip jq apt-transport-https ca-certificates gnupg
usermod -aG docker ubuntu
systemctl enable --now docker

###############################################################################
# 2. kubectl + helm + minikube
###############################################################################
curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod 0755 /usr/local/bin/kubectl

curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor -o /usr/share/keyrings/helm.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" \
  > /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update -y
apt-get install -y helm

curl -fsSLo /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install /tmp/minikube /usr/local/bin/minikube

###############################################################################
# 3. AWS CLI v2 (used for the ESO rotation drill)
###############################################################################
curl -fsSLo /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

###############################################################################
# 4. Start Minikube — sized for full W9 stack on t3.xlarge (4 vCPU / 16 GB)
#    Allocate 4 CPUs and 12 GB to minikube, leaving ~4 GB for OS + Docker.
###############################################################################
sudo -u ubuntu -H bash -lc 'minikube start --driver=docker --cpus=4 --memory=12288 --wait=all'
sudo -u ubuntu -H bash -lc 'mkdir -p /home/ubuntu/.kube && cp /home/ubuntu/.kube/config /home/ubuntu/.kube/config 2>/dev/null || true'

###############################################################################
# 5. Add Helm repos — ArgoCD needs these to sync Helm-type Applications
#    (kube-prometheus-stack, argo-rollouts, ESO, sigstore)
###############################################################################
sudo -u ubuntu -H bash -lc 'helm repo add prometheus-community https://prometheus-community.github.io/helm-charts'
sudo -u ubuntu -H bash -lc 'helm repo add argo https://argoproj.github.io/argo-helm'
sudo -u ubuntu -H bash -lc 'helm repo add external-secrets https://charts.external-secrets.io'
sudo -u ubuntu -H bash -lc 'helm repo add sigstore https://sigstore.github.io/helm-charts'
sudo -u ubuntu -H bash -lc 'helm repo update'

###############################################################################
# 6. ArgoCD (W9 GitOps controller)
###############################################################################
sudo -u ubuntu -H bash -lc 'kubectl create namespace argocd || true'
sudo -u ubuntu -H bash -lc 'kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml'

# Wait for ArgoCD server to be fully ready before applying root app
echo ">>> Waiting for ArgoCD server to be ready..."
sudo -u ubuntu -H bash -lc 'kubectl -n argocd rollout status deployment/argocd-server --timeout=300s'
sudo -u ubuntu -H bash -lc 'kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=300s'
sudo -u ubuntu -H bash -lc 'kubectl -n argocd rollout status deployment/argocd-applicationset-controller --timeout=300s'

###############################################################################
# 7. External Secrets Operator (W10 Lab 2.1)
###############################################################################
sudo -u ubuntu -H bash -lc 'helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --set installCRDs=true --wait --timeout=300s'

###############################################################################
# 8. Sigstore Policy Controller (W10 Lab 2.2)
###############################################################################
sudo -u ubuntu -H bash -lc 'helm upgrade --install policy-controller sigstore/policy-controller \
  -n cosign-system --create-namespace --wait --timeout=300s'

###############################################################################
# 9. Bootstrap ArgoCD root app (app-of-apps) — triggers sync of all W9 apps:
#    mongodb, backend, frontend, kube-prometheus-stack, argo-rollouts, eso, policy
###############################################################################
echo ">>> Bootstrapping ArgoCD root app (app-of-apps)..."
sudo -u ubuntu -H bash -lc 'kubectl apply -f https://raw.githubusercontent.com/X-BRAIN-CDO-09/PhanLeThanhHoang-aws-accelerator-p2/main/cloud/w10/flipkart/argocd/root.yaml'

# Give ArgoCD time to reconcile and start syncing child apps
echo ">>> Waiting 30s for ArgoCD to start reconciling child apps..."
sleep 30

###############################################################################
# 10. Socat tunnels: EC2 ports -> minikube IP ports
#     - ${app_port} (30000): Flipkart frontend (ALB target)
#     - 30001: Grafana NodePort (SSH tunnel)
#     - 30090: Prometheus NodePort (SSH tunnel)
#     - 30080: ArgoCD NodePort (SSH tunnel)
###############################################################################
MINIKUBE_IP=$(sudo -u ubuntu -H bash -lc 'minikube ip')

# Primary: ALB -> Frontend app
nohup socat TCP-LISTEN:${app_port},fork,reuseaddr TCP:$MINIKUBE_IP:${app_port} > /var/log/socat-app.log 2>&1 &

# Monitoring: for SSH tunnel access
nohup socat TCP-LISTEN:30001,fork,reuseaddr TCP:$MINIKUBE_IP:30001 > /var/log/socat-grafana.log 2>&1 &
nohup socat TCP-LISTEN:30090,fork,reuseaddr TCP:$MINIKUBE_IP:30090 > /var/log/socat-prometheus.log 2>&1 &
nohup socat TCP-LISTEN:30080,fork,reuseaddr TCP:$MINIKUBE_IP:30080 > /var/log/socat-argocd.log 2>&1 &

###############################################################################
# 11. Hand-off note
###############################################################################
cat > /home/ubuntu/NEXT-STEPS.md <<EOF
=== W9 Full Stack Bootstrap Complete ===
Instance: t3.xlarge (4 vCPU / 16 GB)
Minikube: --cpus=4 --memory=12288

ArgoCD root app has been applied. All child apps should be syncing now.

--- Check status ---
  kubectl -n argocd get applications
  kubectl -n flipkart get pods
  kubectl -n monitoring get pods
  kubectl -n argo-rollouts get pods
  kubectl -n external-secrets get pods
  kubectl -n cosign-system get pods

--- ArgoCD admin password ---
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d ; echo

--- SSH tunnel from your laptop ---
  ssh -i <key>.pem \\
    -L 8080:127.0.0.1:8080 \\
    -L 3001:127.0.0.1:3001 \\
    -L 9090:127.0.0.1:9090 \\
    ubuntu@<ec2-ip>

  # Then on EC2:
  kubectl -n argocd port-forward svc/argocd-server 8080:443 &
  kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3001:80 &
  kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090 &

--- Cleanup ---
  terraform destroy  # from your local machine when done
EOF
chown ubuntu:ubuntu /home/ubuntu/NEXT-STEPS.md
