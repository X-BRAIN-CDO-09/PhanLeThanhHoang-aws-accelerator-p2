# Thực hành 1: Cài đặt kube-prometheus-stack và xem Dashboard

Bài tập này hướng dẫn cài đặt hệ thống Monitoring trung tâm (Prometheus, Grafana, AlertManager) vào cluster của bạn.

## Bước 1: Cài đặt bằng Helm
Sử dụng Helm để cài đặt `kube-prometheus-stack` vào cluster của bạn.
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

Kiểm tra xem các pod đã lên đủ chưa:
```bash
kubectl get pods -n monitoring
```

## Bước 2: Truy cập Grafana
Mặc định Grafana không được expose ra ngoài. Chạy lệnh sau để truy cập qua Localhost:
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

1. Mở trình duyệt: `http://localhost:3000`
2. Đăng nhập bằng tài khoản mặc định: 
   - Username: `admin`
   - Password: `prom-operator`

## Bước 3: Khám phá Dashboard có sẵn
1. Truy cập vào mục **Dashboards** trên menu trái.
2. Tìm thư mục **General** hoặc các thư mục của Kubernetes.
3. Mở các dashboard như: `Node Exporter / Nodes` hoặc `Kubernetes / Compute Resources / Cluster`.
4. Quan sát các thông số CPU/RAM và dung lượng ổ cứng của Cluster hiện tại.
