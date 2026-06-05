# Hướng dẫn Step-by-Step: Triển khai Counter-App lên K8s trên AWS (Terraform 1-click)

Dựa trên project hiện tại của bạn (`Counter-App`), đây là hướng dẫn chi tiết từng bước để bạn hoàn thành bài Challenge Tuần 8. Cách làm này sử dụng **Minikube**, **Terraform `user_data`** và đẩy ứng dụng thực tế của bạn lên **Docker Hub**.

---

## Giai đoạn 1: Chuẩn bị Ứng dụng (Local)

Mục tiêu của giai đoạn này là biến `Counter-App` của bạn thành một Docker Image và đẩy lên Docker Hub để K8s trên AWS có thể tải về.

### Bước 1: Đăng ký tài khoản Docker Hub
- Truy cập [hub.docker.com](https://hub.docker.com/) và tạo một tài khoản miễn phí (nếu chưa có).
- Ghi nhớ **Username** của bạn.

### Bước 2: Tạo `Dockerfile`
Di chuyển vào thư mục ứng dụng của bạn:
`e:\XBrain\Phase2\PhanLeThanhHoang-aws-accelerator-p2\cloud\w8\week-project\Counter-App`

Tạo một file mới tên là `Dockerfile` (không có đuôi mở rộng) với nội dung sau:
```dockerfile
# Sử dụng Nginx làm web server nhẹ
FROM nginx:alpine

# Copy code của bạn vào thư mục mặc định của Nginx
COPY index.html /usr/share/nginx/html/
COPY main.css /usr/share/nginx/html/
COPY index.js /usr/share/nginx/html/

# Expose port 80
EXPOSE 80
```

### Bước 3: Build và Push Docker Image (Thực hiện trên máy của bạn)
Mở terminal tại thư mục `Counter-App` và chạy lần lượt các lệnh (Thay `<your_dockerhub_username>` bằng username thực tế):

```bash
# 1. Đăng nhập Docker (Nhập username và password)
docker login

# 2. Build image
docker build -t <your_dockerhub_username>/counter-app:v1 .

# 3. Push image lên Docker Hub
docker push <your_dockerhub_username>/counter-app:v1
```
*Sau khi chạy xong, lên trang Docker Hub kiểm tra xem image đã có trên đó chưa.*

---

## Giai đoạn 2: Xây dựng cấu trúc Terraform

Bây giờ bạn sẽ viết code Terraform để tự động tạo hạ tầng và gọi app về.

### Bước 4: Tạo cấu trúc thư mục Terraform
Tại `e:\XBrain\Phase2\PhanLeThanhHoang-aws-accelerator-p2\cloud\w8\week-project\`, tạo một thư mục tên là `terraform`. Cấu trúc của bạn sẽ trông như thế này:

```text
week-project/
├── Counter-App/       # (Đã xử lý xong ở Giai đoạn 1)
│   ├── Dockerfile
│   ├── index.html
│   └── ...
└── terraform/         # (Nơi bạn viết code ở Giai đoạn 2)
    ├── main.tf        # Gọi modules, ALB, EC2...
    ├── network.tf     # VPC, Subnets, Security Groups
    ├── variables.tf   # Biến
    ├── outputs.tf     # In ra URL của ALB
    └── init.sh        # Script user_data quan trọng nhất
```

### Bước 5: Viết code Hạ tầng AWS (`network.tf`, `main.tf`)
*(Phần này bạn dùng kiến thức Terraform tuần trước để tự viết)*
- Cần tạo **1 EC2** (Khuyên dùng `t3.small` Ubuntu để đủ RAM chạy K8s).
- Tạo **Security Group EC2** mở port `22` (SSH) và port `30000` (Port NodePort của app).
- Tạo **ALB** (Application Load Balancer) Internet-facing.
- Tạo **Target Group** trỏ vào IP của EC2, **port `30000`**.
- Tạo **Listener** cho ALB ở port `80` trỏ vào Target Group.
- Trong `main.tf` chỗ khai báo EC2, thêm dòng: `user_data = file("init.sh")`.

---

## Giai đoạn 3: Trái tim của hệ thống (User Data Script)

### Bước 6: Viết file `init.sh`
File này sẽ được EC2 tự động chạy ngay khi bật lên. Tạo file `init.sh` trong thư mục `terraform` với nội dung tham khảo sau:

```bash
#!/bin/bash
# 1. Cài đặt Docker
apt-get update -y
apt-get install -y docker.io
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
        image: <your_dockerhub_username>/counter-app:v1  # Sửa lại thành Username của bạn
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
      nodePort: 30000 # Cố định port này để map với ALB Target Group
EOF

# 7. Apply K8s yaml
sudo -u ubuntu kubectl apply -f /home/ubuntu/app.yaml

# 8. Expose (Nối mạng từ EC2 vào Minikube Container)
# Lệnh này dùng socat để forward traffic từ port 30000 của EC2 host vào port 30000 của minikube IP
apt-get install -y socat
MINIKUBE_IP=\$(sudo -u ubuntu minikube ip)
nohup socat TCP-LISTEN:30000,fork TCP:\$MINIKUBE_IP:30000 &
```

*(Lưu ý về Bước 8: Minikube chạy K8s trong 1 Docker container. Do đó, NodePort 30000 chỉ mở ở IP nội bộ của Minikube, không mở ở IP của máy EC2. Dùng `socat` là một mẹo hiệu quả để forward traffic từ EC2 vào Minikube).*

---

## Giai đoạn 4: Chạy thử và Nghiệm thu

### Bước 7: Deploy bằng Terraform
1. Mở terminal, `cd` vào thư mục `terraform`.
2. Chạy `terraform init`
3. Chạy `terraform apply -auto-approve`
4. Cấu hình file `outputs.tf` in ra giá trị `dns_name` của ALB. Copy đường link đó.

### Bước 8: Chờ đợi và Kiểm tra
- **Kiên nhẫn:** Terraform chạy xong chỉ tốn 2 phút, nhưng cái script `init.sh` bên trong cần tốn khoảng **3 - 5 phút** để tải docker, tải minikube, kéo image app của bạn về.
- Sau 5 phút, dán link ALB vào trình duyệt. Nếu thấy trang `Counter-App` hiện lên -> **CHÚC MỪNG BẠN!**

### (Mẹo Debug nếu bị lỗi)
Nếu sau 10 phút vào ALB vẫn bị lỗi 502/504:
- SSH vào máy EC2: `ssh -i <key> ubuntu@<ip_ec2>`
- Xem log quá trình chạy init: `cat /var/log/cloud-init-output.log`
- Kiểm tra minikube: `minikube status`
- Kiểm tra app: `kubectl get pods`, `kubectl get svc`
