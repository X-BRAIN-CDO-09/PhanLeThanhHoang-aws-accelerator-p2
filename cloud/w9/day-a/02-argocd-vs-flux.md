# GitOps: ArgoCD vs Flux

## 1. GitOps là gì?
GitOps là một bộ các nguyên tắc (principles) để quản lý cấu hình và hạ tầng thông qua Git. Nguyên tắc cốt lõi là:
- Git là **Single Source of Truth** (SSOT) cho cấu hình hệ thống.
- Trạng thái mong muốn (desired state) được định nghĩa declarative trong Git.
- Hệ thống GitOps tự động (automated controllers) kéo (pull) và đồng bộ trạng thái thực tế trong Kubernetes với trạng thái được khai báo trong Git.

## 2. Tại sao chọn Mô hình "Pull" (ArgoCD/Flux) thay vì "Push" (Jenkins/GitHub Actions)?
- **Bảo mật:** Với "Push", hệ thống CI/CD cần có admin credentials để truy cập Kubernetes cluster. Với "Pull", Agent chạy *bên trong* cluster và chỉ gọi ra ngoài Git để lấy code, không cần mở port cho CI server truy cập vào cluster.
- **Drift Reconciliation:** Nếu ai đó tự ý đổi tay (`kubectl edit`) cấu hình trong cluster, ArgoCD/Flux sẽ ngay lập tức phát hiện sự sai lệch (drift) với Git và có thể tự động ghi đè lại để đảm bảo trạng thái chuẩn theo Git. CI truyền thống (Push) chỉ chạy 1 lần lúc merge code nên không có khả năng này.

## 3. So sánh ArgoCD và Flux

| Tiêu chí | ArgoCD | Flux |
|----------|---------|------|
| **UI/UX** | Rất mạnh, có giao diện web cực kì trực quan để theo dõi các app, resource, và sync status. | Chủ yếu dùng CLI, mặc dù gần đây có Weave GitOps Dashboard nhưng không phổ biến bằng. |
| **Kiến trúc** | Quản lý nhiều cluster dễ dàng từ một UI trung tâm (Hub and Spoke). | Thường cài riêng trên từng cluster, thiên về cách tiếp cận phi tập trung (Decentralized). |
| **Tích hợp SSO** | Hỗ trợ SSO/RBAC rất tốt ngay trong cấu hình mặc định (OIDC, SAML, GitHub, v.v.). | Cần config thêm nhiều nếu muốn SSO và RBAC mạnh mẽ. |
| **Tiến độ triển khai**| Có sẵn các Rollout strategies cực mạnh thông qua Argo Rollouts (chung ecosystem). | Có sẵn thông qua Flagger (chung ecosystem). |

**Kết luận:** Trong phạm vi khóa học, **ArgoCD** được ưa chuộng hơn vì UI đẹp, dễ học và dễ hình dung quá trình sync hơn cho người mới bắt đầu với GitOps.
