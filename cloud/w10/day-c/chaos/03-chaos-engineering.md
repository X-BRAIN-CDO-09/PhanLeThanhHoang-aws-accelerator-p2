# Chaos Engineering cơ bản

## 1. Chaos Engineering là gì?
Chaos Engineering là bộ môn thực hành "phá hoại có kiểm soát". Thay vì đợi hệ thống sập do lỗi ngoài ý muốn vào lúc 3 giờ sáng, chúng ta chủ động tạo ra các sự cố (kill pod, cắt mạng, làm đầy ổ cứng, vắt kiệt CPU) vào ban ngày (giờ hành chính) để xem hệ thống phản ứng và tự phục hồi (resilient) ra sao.

*Nguyên tắc:* "Nếu hệ thống bị lỗi, nó nên tự động phục hồi. Nếu không tự phục hồi, monitoring/alerting phải báo động ngay lập tức."

## 2. Công cụ phổ biến trong K8s
- **Chaos Mesh (CNCF):** Cung cấp giao diện trực quan và các CRD cực mạnh để tạo kịch bản lỗi (NetworkChaos, PodChaos, DNSChaos).
- **LitmusChaos (CNCF):** Tập trung mạnh vào các "Chaos Experiment" (thí nghiệm hỗn loạn) dạng K8s resource.

## 3. Ví dụ cấu hình PodChaos (với Chaos Mesh)
Kịch bản: Cứ mỗi phút, xóa ngẫu nhiên 1 Pod của frontend để kiểm tra xem load balancer có điều hướng request sang Pod khác mượt mà không (người dùng không bị gián đoạn).

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-frontend
  namespace: staging
spec:
  action: pod-kill
  mode: one # Xóa 1 pod mỗi lần
  selector:
    labelSelectors:
      app: frontend
  duration: '10s'
  scheduler:
    cron: '@every 1m' # Chạy mỗi phút
```

## 4. Quá trình thực hiện Chaos Experiment (Game Day)
1. **Hypothesis (Giả thuyết):** "Nếu tôi tắt 1/3 số pod frontend, request vẫn thành công 99.9%."
2. **Blast Radius (Phạm vi ảnh hưởng):** Bắt đầu thử nghiệm ở môi trường Staging hoặc với phạm vi nhỏ gọn trên Prod. Tuyệt đối không làm sập toàn bộ hệ thống ngay lần đầu.
3. **Execute (Thực hiện):** Bật kịch bản PodChaos.
4. **Observe (Quan sát):** Xem Dashboard Grafana, xem số lượng lỗi HTTP 5xx có tăng vọt không? Alert có bắn về Slack không?
5. **Analyze (Phân tích):** Nếu request vẫn ổn định -> Hệ thống tốt. Nếu lỗi xảy ra -> Cải thiện code, cấu hình lại Readiness Probe của Kubernetes, chạy lại thí nghiệm đến khi đạt.
