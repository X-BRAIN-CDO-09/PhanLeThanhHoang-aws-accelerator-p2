# Bài tập thực hành Day 1: RBAC + Admission Policy

Trong phần này, "code" chủ yếu là viết các file YAML định nghĩa tài nguyên Kubernetes và viết logic kiểm tra (policy) bằng ngôn ngữ Rego.

## Bài 1: Phân quyền RBAC cơ bản
**Mục tiêu:** Hiểu cách hoạt động của Role và RoleBinding trong việc giới hạn quyền của ServiceAccount.

**Yêu cầu:**
1. Tạo một namespace có tên `team-frontend`.
2. Tạo một ServiceAccount có tên `frontend-developer` trong namespace `team-frontend`.
3. Viết file YAML định nghĩa một `Role` có tên `pod-reader` chỉ cho phép quyền `get`, `list`, `watch` trên tài nguyên `pods`.
4. Viết file YAML định nghĩa một `RoleBinding` để gắn role `pod-reader` cho ServiceAccount `frontend-developer`.
5. **Kiểm tra:** Sử dụng lệnh `kubectl auth can-i` để xác minh:
   - ServiceAccount này có thể list pods trong namespace `team-frontend`.
   - ServiceAccount này KHÔNG thể create pods trong namespace `team-frontend`.
   - ServiceAccount này KHÔNG thể list pods ở namespace khác (ví dụ `kube-system`).

## Bài 2: Gatekeeper & OPA Rego
**Mục tiêu:** Viết policy chặn việc tạo các tài nguyên không tuân thủ tiêu chuẩn bảo mật.

**Yêu cầu:**
1. Cài đặt OPA Gatekeeper lên cluster.
2. Viết file YAML `ConstraintTemplate` chứa logic Rego. Logic này kiểm tra xem một `Namespace` khi tạo ra có chứa label `owner` hay không.
3. Viết file YAML `Constraint` áp dụng template trên, bắt buộc mọi namespace tạo mới phải có label `owner`.
4. **Kiểm tra:**
   - Thử tạo một namespace không có label `owner` -> Phải nhận thông báo lỗi (Webhook bị deny).
   - Thử tạo một namespace có label `owner: "team-a"` -> Thành công.

## Bài 3: Pod Security Standards (Nâng cao)
**Yêu cầu:** Viết một `ValidatingAdmissionPolicy` (hoặc dùng Gatekeeper/Kyverno) để đảm bảo không có Pod nào được phép chạy dưới quyền `root` (phải cấu hình `runAsNonRoot: true` trong securityContext). Thử deploy một pod Nginx mặc định và quan sát nó bị chặn.
