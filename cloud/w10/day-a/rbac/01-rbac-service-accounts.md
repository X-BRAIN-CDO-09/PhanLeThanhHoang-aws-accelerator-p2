# RBAC và Service Accounts trong Kubernetes

## 1. Khái niệm cơ bản
Trong Kubernetes, **RBAC (Role-Based Access Control)** là phương pháp tiêu chuẩn để quản lý quyền truy cập vào các tài nguyên của cluster. RBAC xác định "Ai" có thể làm "Gì" trên "Tài nguyên nào".

Các thành phần chính của RBAC:
- **Entity (Ai):** Có thể là User, Group, hoặc **ServiceAccount**. Trong K8s, ứng dụng chạy trong Pod thường sử dụng ServiceAccount để giao tiếp với API Server.
- **Resource (Tài nguyên nào):** Là các đối tượng trong K8s như Pods, Deployments, Secrets, Namespaces...
- **Verb (Làm gì):** Các hành động có thể thực hiện như `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`.

## 2. Role và ClusterRole
Quyền hạn được định nghĩa thông qua các Role:
- **Role:** Định nghĩa quyền hạn trong phạm vi của MỘT `Namespace` cụ thể.
- **ClusterRole:** Định nghĩa quyền hạn trên TOÀN BỘ cluster, bao gồm cả các tài nguyên không thuộc namespace nào (như Nodes) hoặc muốn áp dụng quyền cho tất cả các namespace.

### Ví dụ về Role:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: team-frontend
  name: pod-reader
rules:
- apiGroups: [""] # "" là core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

## 3. RoleBinding và ClusterRoleBinding
Sau khi định nghĩa quyền (Role), ta cần "gắn" quyền đó cho một Entity (ServiceAccount/User).
- **RoleBinding:** Gắn một Role (hoặc ClusterRole) cho một Entity trong phạm vi MỘT Namespace.
- **ClusterRoleBinding:** Gắn một ClusterRole cho một Entity trên TOÀN BỘ cluster.

### Ví dụ về RoleBinding:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: team-frontend
subjects:
- kind: ServiceAccount
  name: frontend-developer # Tên của ServiceAccount đã được tạo
  namespace: team-frontend
roleRef:
  kind: Role
  name: pod-reader # Phải khớp với tên Role ở trên
  apiGroup: rbac.authorization.k8s.io
```

## 4. Kiểm tra quyền (Testing)
Bạn có thể sử dụng lệnh `kubectl auth can-i` để giả lập và kiểm tra xem một tài khoản có quyền thực hiện hành động hay không:

```bash
# Kiểm tra tư cách user hiện tại
kubectl auth can-i list pods -n team-frontend

# Kiểm tra tư cách của một ServiceAccount cụ thể
kubectl auth can-i create pods -n team-frontend --as=system:serviceaccount:team-frontend:frontend-developer
```

## 5. Best Practices
1. **Nguyên tắc đặc quyền tối thiểu (Principle of Least Privilege):** Chỉ cấp đúng những quyền (verbs, resources) mà ứng dụng thực sự cần.
2. Tránh cấp quyền `*` (wildcard) cho `resources` hoặc `verbs`.
3. Không bao giờ gán quyền `cluster-admin` cho các ứng dụng chạy trong Pod trừ khi đó là các công cụ quản trị hạ tầng cốt lõi (như ArgoCD, Prometheus Operator).
