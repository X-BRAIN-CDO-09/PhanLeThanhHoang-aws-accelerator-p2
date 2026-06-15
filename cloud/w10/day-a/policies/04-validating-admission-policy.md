# Validating Admission Policy (K8s Native)

## 1. Bối cảnh
Trước Kubernetes 1.30 (được giới thiệu ở các bản Beta trước đó), để kiểm tra và chặn các tài nguyên không hợp lệ, ta phải dựng các Admission Webhook (như OPA Gatekeeper, Kyverno). Việc này đòi hỏi phải chạy thêm phần mềm phụ trợ, tốn tài nguyên và tăng độ trễ cho API Server.

Kubernetes đã giới thiệu **ValidatingAdmissionPolicy** – một tính năng K8s Native, cho phép viết các policy đơn giản trực tiếp trên API Server mà không cần webhook bên ngoài.

## 2. Common Expression Language (CEL)
Thay vì sử dụng Rego, ValidatingAdmissionPolicy sử dụng **CEL (Common Expression Language)** của Google. Đây là một ngôn ngữ biểu thức rất nhẹ, an toàn và dễ học, thường được sử dụng trong Envoy, GCP và nay là Kubernetes.

Ví dụ biểu thức CEL cơ bản:
`object.metadata.labels.owner == "team-a"`

## 3. Cấu trúc ValidatingAdmissionPolicy
Tương tự Gatekeeper, tính năng này được chia làm 2 phần:
1. **ValidatingAdmissionPolicy:** Khai báo quy tắc CEL.
2. **ValidatingAdmissionPolicyBinding:** Áp dụng quy tắc đó vào các tài nguyên/namespace cụ thể.

### Ví dụ cấu hình (Không cho chạy container quyền Root)

**Phần 1: Policy**
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: "deny-root-containers"
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups:   [""]
      apiVersions: ["v1"]
      operations:  ["CREATE", "UPDATE"]
      resources:   ["pods"]
  validations:
    - expression: "object.spec.containers.all(c, !has(c.securityContext) || !has(c.securityContext.runAsRoot) || c.securityContext.runAsRoot == false)"
      message: "Không được phép chạy container với quyền root!"
```

**Phần 2: Binding**
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: "deny-root-containers-binding"
spec:
  policyName: "deny-root-containers"
  validationActions: [Deny]
  matchResources:
    namespaceSelector:
      matchExpressions:
      - key: environment
        operator: In
        values: ["production"]
```

## 4. Lợi ích của ValidatingAdmissionPolicy
- **Tốc độ:** Chạy trực tiếp trong tiến trình của kube-apiserver nên tốc độ kiểm tra cực kỳ nhanh (tính bằng microsecond).
- **Đơn giản:** Không cần cài thêm Operator nặng nề, cú pháp CEL dễ đọc hơn Rego đối với các logic đơn giản.
- **Tính khả dụng:** Không lo bị chết webhook gây ảnh hưởng tới toàn bộ việc deploy của cluster.

*(Tuy nhiên, đối với các rule quá phức tạp hoặc yêu cầu kết xuất dữ liệu bên ngoài, Gatekeeper/Kyverno vẫn là lựa chọn tốt).*
