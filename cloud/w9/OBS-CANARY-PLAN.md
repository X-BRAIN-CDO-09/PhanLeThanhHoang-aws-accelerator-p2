# Kế hoạch Observability + Canary cho Flipkart MERN

## 1. Mục tiêu cuối

Áp dụng lab `W9-chieu-obs-canary.html` trực tiếp lên ứng dụng Flipkart đã có:

```text
Git push
  -> ArgoCD root sync
  -> Prometheus scrape metric backend
  -> Argo Rollouts phát hành backend theo canary
  -> AnalysisTemplate query Prometheus
  -> bản tốt tự promote, bản lỗi tự abort
```

Kết quả cần chứng minh:

- Mọi manifest được quản lý qua Git và ArgoCD ở trạng thái `Synced/Healthy`.
- Prometheus đo được traffic, error rate và latency của backend.
- Có availability SLO `99.5%` và burn-rate alert.
- Bản backend tốt tự lên `100%`.
- Bản backend lỗi tự abort về revision ổn định.
- `git revert` rollback trong dưới 5 phút.

## 2. Phạm vi áp dụng

### Backend Node.js/Express

Backend là workload chính để instrument và chạy canary vì:

- Chứa API `/api/v1/*`, nơi phản ánh success rate và latency thực tế.
- Có thể chủ động inject lỗi để kiểm tra alert và auto-abort.
- Một bản backend lỗi có thể được đánh giá bằng metric trước khi nhận toàn bộ traffic.

Backend sẽ được đổi từ `Deployment` thành Argo Rollouts `Rollout`.

### Frontend React/Nginx

Frontend tiếp tục dùng `Deployment` trong vòng đầu:

- Nginx proxy `/api/*` sang Service backend.
- Frontend vẫn tạo traffic thật đến backend.
- Chưa cần canary frontend để giữ lab tập trung và dễ quan sát.

Sau khi backend auto-abort hoạt động, có thể mở rộng Rollout cho frontend.

### MongoDB

MongoDB giữ nguyên `Deployment + PVC`. Không đưa database vào canary.

## 3. Trạng thái hiện tại và rủi ro

- Profile Kubernetes cần dùng: `w9`.
- Cluster `w9` đã được khôi phục và đang `Ready`.
- ArgoCD, backend, frontend và MongoDB đã trở lại trạng thái khỏe.
- Minikube CLI không cho đổi `--memory` và `--cpus` của profile đã tồn tại nếu
  không xóa cluster.
- Vì profile `w9` dùng Docker driver, giới hạn cgroup đã được tăng trực tiếp
  bằng `docker update` mà không xóa cluster.
- Cgroup hiện cấp cho node `w9`: `8 GiB RAM` và thêm `2 GiB swap`.
- Backend chưa có `/metrics`, `/healthz`, `APP_VERSION` hoặc `ERROR_RATE`.
- Backend đang dùng image tag `latest`; canary cần tag bất biến như
  `backend:v1`, `backend:v2-good`, `backend:v2-bad`.

Không xóa profile `w9` chỉ để resize vì thao tác đó làm mất trạng thái hiện tại.
Giới hạn từ `docker update` có thể cần áp dụng lại nếu container `w9` bị Minikube
xóa và tạo mới.

## 4. Cấu trúc sẽ tạo

```text
w9-sang-gitops-final/
  argocd/apps/
    kube-prometheus-stack.yaml
    argo-rollouts.yaml
    backend.yaml
    frontend.yaml
  app/
    backend/
      app.js
      observability/
        metrics.js
    Dockerfile.backend
  flipkart/k8s/
    backend/
      mongodb.yaml
      backend-services.yaml
      backend-rollout.yaml
      backend-servicemonitor.yaml
      backend-analysis-template.yaml
      backend-prometheus-rules.yaml
    frontend/
      frontend.yaml
  obs-canary/
    load-test/
      backend-load.js
    evidence/
      README.md
```

## 5. Kế hoạch thực hiện

### Giai đoạn 0 - Khôi phục và kiểm tra cluster

Mục tiêu: profile `w9` hoạt động và đủ tài nguyên trước khi cài monitoring.

```bash
minikube status -p w9
docker update --memory 8g --memory-swap 10g w9
minikube start -p w9
minikube update-context -p w9
kubectl config use-context w9
kubectl get nodes
kubectl get applications -n argocd
```

Kiểm tra mức sử dụng tài nguyên:

```bash
kubectl top nodes
kubectl get pods -A
```

**Hoàn thành khi:** node `w9` là `Ready`, ArgoCD hoạt động, ứng dụng Flipkart
vẫn chạy và cluster có đủ khoảng trống cho monitoring stack.

### Giai đoạn 1 - Cài nền tảng qua App-of-Apps

Tạo hai child Application Helm:

- `kube-prometheus-stack` vào namespace `monitoring`.
- `argo-rollouts` vào namespace `argo-rollouts`.

Prometheus cần cho phép đọc `ServiceMonitor` và `PrometheusRule` do ứng dụng tạo:

```yaml
prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false
```

Monitoring vẫn dùng cấu hình gọn để lab ổn định và khởi động nhanh:

- Chỉ giữ Prometheus, Grafana, Alertmanager và Prometheus Operator.
- Tắt node exporter, kube-state-metrics và các component monitors không dùng.
- Giới hạn retention Prometheus cho phạm vi lab.
- Đặt resource requests/limits nhỏ và theo dõi OOM trước khi sang bước tiếp.

Chỉ cài qua Git:

```bash
git add cloud/w9/w9-sang-gitops-final/argocd/apps
git commit -m "[W9-Lab] Add observability and rollout platforms"
git push
```

**Hoàn thành khi:** hai Application mới `Synced/Healthy`; Prometheus, Grafana
và Argo Rollouts controller đều `Running`.

### Giai đoạn 2 - Instrument backend Express

Thêm package `prom-client` và middleware đo:

- Counter `flipkart_http_requests_total`.
- Histogram `flipkart_http_request_duration_seconds`.
- Labels tối thiểu: `method`, `route`, `status_code`, `version`.
- `GET /metrics` để Prometheus scrape.
- `GET /healthz` để probe backend.
- `APP_VERSION` để phân biệt stable/canary.
- `ERROR_RATE` để inject lỗi có kiểm soát phục vụ bad release.

Không inject lỗi vào `/healthz` và `/metrics`.

Build ba tag image:

```bash
docker build \
  -f cloud/w9/w9-sang-gitops-final/app/Dockerfile.backend \
  -t flipkart-backend:v1 \
  cloud/w9/w9-sang-gitops-final/app

docker tag flipkart-backend:v1 flipkart-backend:v2-good
```

Image `v2-bad` được build sau khi đặt `ERROR_RATE` ở manifest, không cần thay đổi
code hoặc tạo image cố tình hỏng.

Nạp image vào đúng profile:

```bash
minikube image load flipkart-backend:v1 -p w9
minikube image load flipkart-backend:v2-good -p w9
```

**Hoàn thành khi:** gọi `/healthz` trả `200`, `/metrics` có metric
`flipkart_http_requests_total`, image tag không dùng `latest`.

### Giai đoạn 3 - Chuyển backend thành Rollout thủ công

Thay backend `Deployment` bằng:

- `Rollout flipkart-backend`, ban đầu `4 replicas`.
- Stable Service `flipkart-backend`.
- Canary Service `flipkart-backend-canary`.
- Canary steps: `25% -> pause tay -> 50% -> pause 30s -> 100%`.

Frontend tiếp tục gọi `flipkart-backend:4000`, tức stable/active service.

Đổi probe backend sang HTTP:

```text
readinessProbe: /healthz
livenessProbe: /healthz
```

**Hoàn thành khi:** đổi image/version qua Git khiến Rollout dừng ở `25%`;
thử được cả `promote` và `abort` bằng tay.

### Giai đoạn 4 - Prometheus scrape metric thật

Tạo `ServiceMonitor` cho backend:

- Chọn Service bằng label `app: flipkart-backend`.
- Scrape named port `http`.
- Path `/metrics`.
- Interval `15s`.

Tạo traffic liên tục vào frontend hoặc backend bằng k6. Query khởi đầu:

```promql
sum(rate(flipkart_http_requests_total[2m]))
```

```promql
sum(rate(flipkart_http_requests_total{status_code=~"5.."}[2m]))
/
clamp_min(sum(rate(flipkart_http_requests_total[2m])), 1)
```

```promql
histogram_quantile(
  0.95,
  sum by (le) (rate(flipkart_http_request_duration_seconds_bucket[5m]))
)
```

**Hoàn thành khi:** Prometheus target backend là `UP`; request counter tăng khi
có traffic; Grafana hiển thị traffic, error ratio và p95 latency.

### Giai đoạn 5 - SLO và burn-rate alert

Availability SLI:

```text
successful requests / total requests
```

Availability SLO:

```text
99.5% trong 30 ngày
```

Error budget:

```text
0.5%
```

Tạo `PrometheusRule` gồm:

- Recording rule cho request rate.
- Recording rule cho error ratio.
- Fast burn alert cho lỗi tăng mạnh.
- Slow burn alert cho lỗi kéo dài.

Trong lab có thể rút ngắn cửa sổ để alert fire nhanh, nhưng README phải ghi rõ
đây là ngưỡng demo. Email Alertmanager cần Secret ngoài Git.

**Hoàn thành khi:** tăng `ERROR_RATE` làm alert chuyển sang `Firing` và gửi email.

### Giai đoạn 6 - Canary auto-abort

Tạo `AnalysisTemplate` query Prometheus theo success rate của backend:

```text
successCondition: result[0] >= 0.95
failureLimit: 3
```

Gắn analysis vào Rollout và bỏ pause vô hạn.

Kịch bản good release:

```text
APP_VERSION=v2-good
ERROR_RATE=0
```

Kỳ vọng: AnalysisRun thành công và Rollout tự lên `100%`.

Kịch bản bad release:

```text
APP_VERSION=v2-bad
ERROR_RATE=0.5
```

Kỳ vọng: success rate giảm, AnalysisRun thất bại và Rollout tự abort về stable
revision mà không dùng lệnh abort tay.

**Hoàn thành khi:** có bằng chứng good release tự promote và bad release tự abort.

### Giai đoạn 7 - Evidence và rollback Git

Lưu bằng chứng trong `obs-canary/evidence/README.md`:

- ArgoCD Applications `Synced/Healthy`.
- Prometheus target backend `UP`.
- PromQL traffic, error ratio và p95 latency.
- Burn-rate alert ở trạng thái `Firing`.
- Email Alertmanager.
- Good AnalysisRun thành công.
- Bad AnalysisRun thất bại và Rollout auto-abort.
- Thời gian thực hiện `git revert` đến khi ArgoCD sync xong.

#### Evidence bắt buộc để đạt bài

Chụp ảnh hoặc quay clip theo đúng thứ tự dưới đây:

1. `01-argocd-applications-healthy.png`
   - Giao diện ArgoCD hiển thị `root`, `flipkart-backend`,
     `flipkart-frontend`, `kube-prometheus-stack`, `argo-rollouts`.
   - Các Application cần ở trạng thái `Synced/Healthy`.
   - Ảnh này chứng minh thay đổi đi qua GitOps và không có drift.

2. `02-prometheus-backend-target-up.png`
   - Prometheus `Status -> Targets`.
   - Target từ `ServiceMonitor` của backend phải là `UP`.
   - Nhìn thấy endpoint `/metrics` và namespace `flipkart`.

3. `03-prometheus-sli-queries.png`
   - Prometheus hoặc Grafana hiển thị ba metric:
     traffic, error ratio và p95 latency.
   - Query và khoảng thời gian phải xuất hiện trong ảnh.

4. `04-slo-alert-firing.png`
   - Alert Prometheus/Alertmanager chuyển sang `Firing` sau khi inject lỗi.
   - Ảnh cần thấy tên alert, severity và thời điểm bắt đầu.

5. `05-alert-email.png`
   - Email cá nhân nhận cảnh báo từ Alertmanager.
   - Có thể che địa chỉ email hoặc dữ liệu nhạy cảm trước khi nộp.

6. `06-manual-canary-paused-25.png`
   - Argo Rollouts dashboard hoặc terminal hiển thị Rollout đang dừng ở `25%`.
   - Stable và canary ReplicaSet cùng tồn tại.

7. `07-good-release-analysis-success.png`
   - AnalysisRun của `v2-good` ở trạng thái `Successful`.
   - Rollout hoàn thành `Healthy`, version mới lên `100%`.

8. `08-bad-release-auto-abort.png`
   - AnalysisRun của `v2-bad` ở trạng thái `Failed`.
   - Rollout ở trạng thái `Degraded/Aborted` và stable revision vẫn phục vụ.
   - Đây là evidence quan trọng nhất; nên quay thêm clip từ lúc đổi Git đến lúc
     auto-abort mà không chạy lệnh abort tay.

9. `09-git-revert-under-5-minutes.png`
   - Hiển thị commit lỗi, commit `git revert`, thời gian bắt đầu/kết thúc và
     ArgoCD trở lại `Synced/Healthy`.
   - Tổng thời gian phải dưới 5 phút.

#### Evidence nên có để trình bày

- `10-grafana-overview-dashboard.png`: dashboard tổng hợp traffic/error/latency.
- `11-rollout-resource-tree.png`: resource tree trên ArgoCD của backend Rollout.
- `12-flipkart-ui-working.png`: giao diện Flipkart vẫn hoạt động sau rollout.
- `13-mongodb-data-preserved.png`: sản phẩm seed vẫn còn sau good/bad release.

#### Output text cần lưu

Không cần chụp mọi terminal output. Lưu các output này thành text trong thư mục
evidence để dễ kiểm tra lại:

```bash
kubectl get applications -n argocd
kubectl get pods -A
kubectl argo rollouts get rollout flipkart-backend -n flipkart
kubectl get analysisrun -n flipkart
kubectl describe analysisrun -n flipkart
kubectl get prometheusrule,servicemonitor -n flipkart
git log --oneline --decorate -10
```

Tên file đề xuất:

```text
applications.txt
pods.txt
rollout-good.txt
rollout-bad.txt
analysisruns.txt
prometheus-resources.txt
git-log.txt
rollback-timing.txt
```

#### Quy tắc chụp evidence

- Ảnh phải thấy tên resource, namespace, trạng thái và thời gian khi có thể.
- Chụp sau khi trạng thái ổn định; tránh ảnh chỉ có `Progressing`.
- Không để Secret, token, password hoặc email cá nhân đầy đủ trong ảnh.
- Với auto-abort và rollback, ưu tiên quay clip ngắn vì một ảnh đơn lẻ không
  chứng minh được hệ thống tự thực hiện.
- Ghi dưới mỗi evidence: lệnh/query đã dùng, kết quả quan sát và lý do evidence
  đó chứng minh checkpoint đạt.

## 6. Thứ tự bắt đầu ngay

1. Xác nhận profile `w9` vẫn giữ giới hạn `8 GiB RAM`.
2. Xác nhận Flipkart và ArgoCD vẫn hoạt động.
3. Tạo hai Helm Application cho Prometheus và Argo Rollouts.
4. Instrument backend Express và build image tag `v1`.
5. Tạo ServiceMonitor, xác nhận metric thật trước.
6. Chuyển backend sang manual Rollout.
7. Viết SLO/alert sau khi metric ổn định.
8. Cuối cùng mới gắn AnalysisTemplate để auto-abort.

## 7. Quyết định kỹ thuật

- Canary backend trước, frontend sau.
- Dùng metric thật từ Express, không tạo Flask API phụ.
- Dùng image tag bất biến, không dùng `latest` cho Rollout.
- Prometheus/Grafana và Rollouts được cài bằng ArgoCD App-of-Apps.
- Loki, traces và OpenTelemetry là phần mở rộng sau khi hoàn thành yêu cầu
  metrics + SLO + auto-abort.

## 8. Tiến độ hiện tại

- [x] Đọc và ánh xạ lab chiều vào repo Flipkart hiện tại.
- [x] Khôi phục profile `w9` và kubeconfig.
- [x] Xác nhận ArgoCD và Flipkart trở lại trạng thái khỏe.
- [x] Nâng giới hạn cgroup node `w9` lên `8 GiB RAM` mà không xóa cluster.
- [x] Chuẩn bị Application `kube-prometheus-stack` cấu hình gọn.
- [x] Chuẩn bị Application `argo-rollouts`.
- [ ] Commit/push hai Application để root bắt đầu cài nền tảng.
- [x] Thêm code instrumentation cho backend Express.
- [ ] Build image backend mới và kiểm tra `/healthz`, `/metrics`.
- [ ] Chuyển backend Deployment thành Rollout.
- [ ] Tạo ServiceMonitor, SLO rules và AnalysisTemplate.
- [ ] Chứng minh good release và bad release auto-abort.
