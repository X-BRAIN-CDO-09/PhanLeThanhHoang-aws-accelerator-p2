# Abort Criteria & Tích hợp với Burn Rate

Khi làm Canary Deployment, mục đích tối thượng là bảo vệ SLO (Service Level Objective). Do đó, các tiêu chí thất bại (Abort Criteria) trong quá trình Canary nên được gắn kết chặt chẽ với phương pháp Burn Rate.

## 1. Abort Criteria trong AnalysisTemplate
Thay vì chỉ viết câu query kiểm tra "Tỷ lệ lỗi > 5%", chúng ta có thể làm chuyên nghiệp hơn bằng cách viết query kiểm tra Burn Rate hiện tại của Canary Pod.

Nếu Canary Pod bắt đầu xài hết Error Budget với tốc độ quá nhanh (Burn Rate cao), đó là dấu hiệu chắc chắn phải Abort.

## 2. Tích hợp Burn Rate vào AnalysisQuery
Sử dụng Prometheus Query để tính Burn Rate của riêng nhóm Pod Canary (thường được đánh nhãn đặc biệt bởi Argo Rollouts, vd: `rollouts-pod-template-hash=xyz`).

```yaml
# Ví dụ cấu hình AnalysisTemplate đo Error Burn Rate
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: burn-rate-analysis
spec:
  metrics:
  - name: error-burn-rate
    interval: 2m
    # Nếu kết quả Burn Rate trả về nhỏ hơn 14.4 (Fast Burn Threshold) thì Success
    successCondition: len(result) == 0 || result[0] < 14.4
    provider:
      prometheus:
        address: http://prometheus-server...
        # Query tính Burn Rate trong khung 5m cho service đang được test
        query: >
          rate(http_requests_total{status=~"5..", pod=~".*-canary-.*"}[5m])
          /
          rate(http_requests_total{pod=~".*-canary-.*"}[5m])
          * 100
```

## 3. Lợi ích của việc đo đếm bằng Burn Rate
- **Đồng nhất tư duy toàn công ty:** Không cần phải định nghĩa lại "thế nào là lỗi" cho từng service riêng lẻ lúc deploy. Cứ hễ vi phạm SLO chung là ngừng deploy.
- **Giảm False Positive:** Khi traffic đang rất ít (mới mở 5%), một vài request lỗi lặt vặt có thể đẩy error rate lên cao. Bằng cách dùng phương pháp luận Burn Rate/Error Budget, các con số sẽ mượt mà (smooth) và chính xác hơn về việc nó có ảnh hưởng đến bức tranh tổng thể hay không.

## 4. Tự động hóa hoàn toàn (Auto-abort)
Với sự kết hợp của:
`GitOps (đẩy code)` -> `ArgoCD (Deploy)` -> `Argo Rollout (Mở 10% traffic)` -> `Analysis Template (Đo Burn Rate)` -> `Prometheus (Trả kết quả fail)` -> `Argo Rollout (Auto-abort)`.

Lập trình viên hoàn toàn có thể an tâm tự merge code vào chiều thứ 6 mà không sợ phá vỡ hệ thống, vì nếu code lỏm, hệ thống sẽ tự chặn và rollback trong vòng chưa đầy 5 phút!
