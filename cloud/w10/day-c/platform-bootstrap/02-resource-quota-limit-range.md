# Quản lý tài nguyên K8s: ResourceQuota & LimitRange

## 1. Khái niệm Requests và Limits
Mỗi container trong K8s có thể khai báo:
- **Requests:** Lượng tài nguyên *tối thiểu* mà node phải đảm bảo có sẵn để Pod được schedule lên đó.
- **Limits:** Lượng tài nguyên *tối đa* mà container được phép sử dụng. Vượt quá giới hạn CPU sẽ bị bóp (throttle), vượt quá giới hạn RAM sẽ bị K8s kill (OOMKilled).

## 2. Bài toán "Noisy Neighbor"
Nếu bạn cấp cho dev một namespace để chạy ứng dụng, nhưng dev quên không thiết lập `requests/limits`. Hậu quả là nếu ứng dụng bị lỗi memory leak, nó sẽ ăn hết toàn bộ RAM của Node, khiến các ứng dụng của team khác chạy trên cùng Node đó chết theo. K8s cung cấp 2 công cụ để phòng chống việc này.

## 3. LimitRange (Cấp độ Container/Pod)
Dùng để tự động gán giá trị mặc định cho những container KHÔNG khai báo resources, và thiết lập mức trần/sàn cho 1 Pod/Container.

**Ví dụ:**
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: staging
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "256Mi"
    type: Container
```
Với cấu hình này, bất kỳ Pod nào tạo ra trong namespace `staging` mà dev quên khai báo resource, nó sẽ tự động bị gán limit là 500m CPU và 512Mi RAM.

## 4. ResourceQuota (Cấp độ Namespace)
Dùng để giới hạn *tổng cộng* tài nguyên của toàn bộ namespace (tổng các Pod cộng lại). Giống như cấp ngân sách cho một dự án.

**Ví dụ:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: staging-quota
  namespace: staging
spec:
  hard:
    pods: "10"             # Tối đa 10 Pods
    requests.cpu: "2"      # Tổng requests CPU của cả namespace không vượt quá 2 core
    requests.memory: "4Gi" # Tổng requests RAM không vượt quá 4 GB
    limits.cpu: "4"        # Tổng limits CPU không vượt quá 4 core
    limits.memory: "8Gi"   # Tổng limits RAM không vượt quá 8 GB
```

## 5. Best Practices
1. Luôn khai báo Limits và Requests cho mọi ứng dụng lên Production.
2. Thiết lập ResourceQuota cho từng namespace để kiểm soát chi phí hạ tầng (Chargeback/Showback).
3. Đảm bảo tổng requests của các namespace không vượt quá tổng tài nguyên thực tế của các node trong Cluster quá nhiều (tránh tình trạng overcommit dẫn đến cluster treo).
