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

# 6. Tạo file YAML cho K8s
cat <<EOF > /home/ubuntu/app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: counter-app-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: counter-app
  template:
    metadata:
      labels:
        app: counter-app
    spec:
      containers:
      - name: counter-app
        image: hofang42/counter-app:v1
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: counter-app-svc
spec:
  type: NodePort
  selector:
    app: counter-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: ${app_port}
EOF

# 7. Apply K8s yaml
sudo -u ubuntu kubectl apply -f /home/ubuntu/app.yaml

# 8. Expose (Nối mạng từ EC2 host vào Minikube Container)
# Lấy IP nội bộ của Minikube
MINIKUBE_IP=$(sudo -u ubuntu minikube ip)

# Forward traffic từ port ${app_port} của EC2 sang port ${app_port} của Minikube
nohup socat TCP-LISTEN:${app_port},fork,reuseaddr TCP:$MINIKUBE_IP:${app_port} &
