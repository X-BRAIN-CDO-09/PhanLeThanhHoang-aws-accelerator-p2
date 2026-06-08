# W8 Reflection

*(Ghi chú các kiến thức học được, những khó khăn và cách giải quyết trong tuần 8 về Terraform và Kubernetes)*

## 1. Kiến thức đã học (What I Learned)

### 1.1. Terraform (Infrastructure as Code)
- **Modularization (Mô-đun hóa):** Đã học cách refactor mã cơ sở hạ tầng (infrastructure code) từ dạng phẳng (flat) sang cấu trúc module chuyên biệt (`network`, `compute`, `loadbalancing`, `vpc`, `security_groups`, `rds`, `s3`). Việc này giúp code tái sử dụng được, dễ bảo trì và chuẩn bị cho môi trường enterprise.
- **Remote State Management:** Cấu hình thành công S3 backend để lưu trữ file state (`terraform.tfstate`) và sử dụng DynamoDB để state locking. Điều này giúp quản lý state an toàn, tránh conflict khi làm việc nhóm (team collaboration).
- **Configuration Management:** Quản lý cấu hình linh hoạt thông qua các biến (variables), sử dụng file `terraform.tfvars` cho từng môi trường cụ thể, dynamic AMI selection, và đánh dấu `sensitive` cho các biến nhạy cảm như mật khẩu.
- **Automation:** Xây dựng luồng triển khai hạ tầng tự động (1-click deployment) kết hợp các tài nguyên một cách liền mạch.

### 1.2. Kubernetes (K8s) & Containerization
- **Cài đặt & Công cụ:** Hiểu rõ mục đích và cách cài đặt `Minikube`, `kubectl` trên môi trường Linux (AWS EC2). 
- **Quản lý Kubernetes Resources:** Thực hành làm việc với các thành phần cốt lõi của Kubernetes như Pods, Deployments, và ReplicaSets thông qua việc triển khai containerized "Counter-App".
- **Networking & Traffic Routing:** Hiểu cách sử dụng `socat` để thực hiện port-forwarding, giúp đưa traffic từ host (EC2) vào bên trong cluster Minikube.

### 1.3. AWS Architecture Integration
- **End-to-end Workflow:** Hiểu và triển khai thành công luồng kiến trúc: `Client -> AWS Application Load Balancer (ALB) -> EC2 Instance -> Minikube (socat port-forwarding) -> Pods (Counter-App)`.
- **Resource Cleanup:** Nắm rõ quy trình dọn dẹp các tài nguyên hạ tầng AWS và Kubernetes an toàn sau khi hoàn thành lab.

## 2. Khó khăn gặp phải (Challenges)

- **Định tuyến (Routing) từ AWS vào Minikube:** Gặp khó khăn trong việc hiểu làm thế nào để Load Balancer (ALB) bên ngoài AWS có thể trỏ traffic vào ứng dụng đang chạy bên trong Minikube (vốn là một cluster thu nhỏ nằm trong một máy ảo EC2).
- **Refactor Terraform Code:** Quá trình chuyển đổi từ code flat sang module khá phức tạp, dễ gặp lỗi liên kết giữa các biến (variables) và output của các module với nhau.
- **Troubleshooting K8s & Git:** Gặp các vấn đề về quyền SSH, cấu hình Git submodule bị lỗi cho source code ứng dụng, và lỗi không thể kết nối tới Kubernetes API server khi muốn xóa (cleanup) tài nguyên.

## 3. Cách giải quyết (Solutions)

- **Trực quan hóa hệ thống:** Sử dụng Mermaid để vẽ sơ đồ triển khai kiến trúc (Deployment Architecture Diagram). Nhờ việc trực quan hóa, tôi hiểu rõ luồng đi của request và lý do tại sao phải dùng `socat` làm cầu nối giữa EC2 port và Minikube service.
- **Chia nhỏ công việc (Break down tasks):** Chia dự án W8 thành các tác vụ nhỏ theo từng ngày (Day A, B, C) như: setup network, sau đó module hóa, cuối cùng mới cấu hình K8s. Điều này giúp dễ dàng kiểm thử và debug ở mỗi bước.
- **Kiểm tra từng bước (Iterative testing):** Thay vì apply toàn bộ hệ thống ngay từ đầu, tôi dùng `terraform plan` và `terraform apply` cho từng module nhỏ để đảm bảo chúng hoạt động trước khi ráp lại thành luồng end-to-end. Chủ động tìm hiểu sâu vào log và output của `kubectl` để debug các lỗi của Pod/Deployment.

## 4. Bài học rút ra (Key Takeaways)
- Thiết kế hệ thống Infrastructure as Code cần tính đến khả năng mở rộng (scalability) và quản lý state ngay từ những ngày đầu.
- Nắm vững kiến thức Networking (Port, Protocol, Routing) là chìa khóa cực kỳ quan trọng để debug thành công các ứng dụng chạy trên nền tảng Container/Kubernetes trên Cloud.
