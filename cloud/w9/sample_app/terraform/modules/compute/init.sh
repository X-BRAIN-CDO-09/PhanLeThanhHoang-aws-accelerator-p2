#!/bin/bash
# 1. Cài đặt Docker và Socat
apt-get update -y
apt-get install -y docker.io socat
usermod -aG docker ubuntu
systemctl start docker
systemctl enable docker

# 2. Cài đặt Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# 3. Cài đặt kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 4. Khởi động Minikube (Chạy với quyền user ubuntu)
sudo -u ubuntu minikube start --driver=docker

# 5. Đợi Minikube sẵn sàng
sleep 30


# 8. Cài đặt ArgoCD
# Tạo namespace argocd
sudo -u ubuntu kubectl create namespace argocd
# Apply file cài đặt ArgoCD
sudo -u ubuntu kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 9. Khởi tạo ArgoCD Application (Tự động mồi GitOps)
# Cần đợi một chút để CRD Application của ArgoCD được Kubernetes nạp xong
sleep 20

cat <<EOF > /home/ubuntu/counter-app-argocd.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: counter-app-gitops
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/X-BRAIN-CDO-09/PhanLeThanhHoang-aws-accelerator-p2.git'
    path: 'cloud/w9/sample_app/Counter-App/kubernetes' 
    targetRevision: HEAD
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

sudo -u ubuntu kubectl apply -f /home/ubuntu/counter-app-argocd.yaml

# 10. Expose (Nối mạng từ EC2 host vào Minikube Container)
# Lấy IP nội bộ của Minikube
MINIKUBE_IP=$(sudo -u ubuntu minikube ip)

# Forward traffic từ port ${app_port} của EC2 sang port ${app_port} của Minikube
nohup socat TCP-LISTEN:${app_port},fork,reuseaddr TCP:$MINIKUBE_IP:${app_port} &
