# Quản lý Secret tự động với ESO và AWS Secrets Manager

## 1. Vấn đề của Kubernetes Secrets
Mặc định, tài nguyên `Secret` trong Kubernetes chỉ được mã hóa dạng **Base64**. Bất kỳ ai có quyền truy cập vào namespace đó đều có thể dễ dàng giải mã và lấy được secret (password, API keys). Việc lưu trữ secret dưới dạng text trong Git repo cũng tiềm ẩn nguy cơ lộ lọt thông tin cực kỳ lớn.

## 2. Giải pháp: External Secrets Operator (ESO)
**ESO** là một Kubernetes operator giúp giải quyết vấn đề trên. Nó kết nối trực tiếp với các dịch vụ quản lý Secret bên ngoài (như AWS Secrets Manager, HashiCorp Vault, Azure Key Vault, Google Secret Manager), đọc giá trị từ đó và tự động tạo ra một `Secret` của K8s.

- Không cần lưu mật khẩu vào Git.
- Tự động xoay vòng (rotate) và đồng bộ lại secret khi có thay đổi trên AWS.
- An toàn và tuân thủ các tiêu chuẩn bảo mật.

## 3. Kiến trúc ESO với AWS
1. **IRSA (IAM Roles for Service Accounts):** Bạn cấu hình một OIDC provider cho EKS/K8s. Sau đó tạo một IAM Role trên AWS cấp quyền `secretsmanager:GetSecretValue`. K8s ServiceAccount của ESO sẽ được liên kết với IAM Role này.
2. **SecretStore:** K8s resource khai báo cho ESO biết *nơi* cần kết nối (VD: AWS Secrets Manager, region `ap-southeast-1`) và *cách* xác thực (dùng ServiceAccount IRSA ở trên).
3. **ExternalSecret:** K8s resource khai báo cho ESO biết cần lấy secret *nào* trên AWS, và tạo ra K8s Secret *tên gì* ở namespace hiện tại.

## 4. Ví dụ Cấu hình

**Bước 1: Tạo SecretStore**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-southeast-1
      auth:
        jwt:
          serviceAccountRef:
            name: eso-service-account # SA đã map với IAM Role
            namespace: external-secrets
```

**Bước 2: Tạo ExternalSecret**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-db-secret
  namespace: app-production
spec:
  refreshInterval: "1m" # Cứ 1 phút ESO lại lên AWS check xem có đổi password không
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: db-credentials # Tên K8s Secret sẽ được ESO tạo ra
    creationPolicy: Owner
  data:
  - secretKey: password # Key trong K8s Secret
    remoteRef:
      key: prod/db-password # Tên Secret lưu trên AWS
```

Sau khi Apply file này, K8s sẽ tự động sinh ra một `Secret` tên là `db-credentials` chứa password lấy từ AWS.
