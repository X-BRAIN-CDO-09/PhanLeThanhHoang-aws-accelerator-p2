# Argo Rollouts: AnalysisTemplate

Trong kỹ thuật Canary, để hệ thống biết được bản mới đang "chạy tốt" hay "có lỗi", chúng ta không thể dùng mắt người để nhìn Dashboard. Chúng ta cần hệ thống tự động hóa việc đọc dữ liệu từ Prometheus. Đó là lúc cần đến `AnalysisTemplate`.

## 1. AnalysisTemplate là gì?
`AnalysisTemplate` là một CRD của Argo Rollouts, chứa định nghĩa về **cách để truy vấn Metrics** và **tiêu chí để xác định Thành Công hay Thất Bại**.

Nó giống như một "bài kiểm tra sức khỏe" định kì cho ứng dụng đang ở giai đoạn Canary.

## 2. Cấu trúc AnalysisTemplate
Một AnalysisTemplate tích hợp với Prometheus sẽ chứa:
- **Provider:** Nguồn lấy dữ liệu (Prometheus, Datadog, NewRelic...).
- **Query:** Câu lệnh truy vấn (PromQL) trả về kết quả số.
- **SuccessCondition / FailureCondition:** Điều kiện kiểm tra kết quả trả về.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 1m      # 1 phút chạy kiểm tra 1 lần
    count: 3          # Kiểm tra tổng cộng 3 lần
    successCondition: result[0] >= 0.95 # Tỷ lệ thành công phải lớn hơn 95%
    failureLimit: 0   # Nếu fail 1 lần là rớt bài kiểm tra luôn
    provider:
      prometheus:
        address: http://prometheus-server.monitoring.svc.cluster.local:9090
        query: |
          sum(rate(http_requests_total{status=~"2.*", service="{{args.service-name}}"}[5m])) 
          / 
          sum(rate(http_requests_total{service="{{args.service-name}}"}[5m]))
```

## 3. Gắn AnalysisTemplate vào Rollout
Sau khi định nghĩa `AnalysisTemplate`, bạn gọi nó trong `Rollout` tại các bước (steps) mà bạn muốn quá trình kiểm tra diễn ra.
Ví dụ: Sau khi đưa 20% traffic vào bản mới, chạy Analysis trong 5 phút. Nếu Analysis trả về SUCCESS, mới tiến hành bước tiếp theo. Nếu FAILURE, Argo tự động Rollback (hủy bản mới, trả 100% về bản cũ).
