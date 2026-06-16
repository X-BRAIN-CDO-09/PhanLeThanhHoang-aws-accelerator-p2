# Image Signing với Cosign và Admission Control

## 1. Vấn đề
Ngay cả khi bạn đã scan image trên CI/CD, kẻ tấn công vẫn có thể đẩy một image giả mạo cùng tên (hoặc thẻ tag bị ghi đè) lên Container Registry. Nếu K8s tải image đó về, nó sẽ chạy mã độc.

Làm sao Kubernetes biết chắc chắn rằng image chuẩn bị kéo về là do chính CI/CD pipeline của bạn tạo ra và chưa bị ai sửa đổi?

## 2. Giải pháp: Image Signing với Sigstore/Cosign
**Cosign** là một công cụ thuộc dự án Sigstore của Linux Foundation, giúp bạn Ký (Sign) và Xác minh (Verify) container images một cách an toàn và dễ dàng.

- **Ký (Sign):** Sau khi CI/CD build xong image, nó dùng Private Key để ký lên image đó, thông tin chữ ký được đẩy thẳng lên Container Registry.
- **Xác minh (Verify):** Trước khi deploy, ta dùng Public Key để kiểm tra xem image đó có đúng chữ ký không.

### 2.1 Quá trình Ký image (trên CI hoặc Local)
```bash
# 1. Tạo cặp key pub/priv
cosign generate-key-pair

# 2. Build và push image
docker build -t my-repo/my-app:1.0 .
docker push my-repo/my-app:1.0

# 3. Ký image
cosign sign --key cosign.key my-repo/my-app:1.0
```

## 3. Bắt buộc K8s chỉ chạy Image đã ký (Admission Control)
Để ngăn chặn Kubernetes chạy các image lạ hoặc chưa được ký, ta có thể dùng OPA Gatekeeper hoặc **Kyverno**. 

Ví dụ với **Kyverno** (một policy engine K8s native rất mạnh về việc kiểm tra image signature):

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: verify-image-signature
      match:
        resources:
          kinds:
            - Pod
      verifyImages:
      - image: "my-repo/*" # Chỉ áp dụng cho image xuất phát từ my-repo
        key: "k8s://kyverno/cosign-pub-key" # Đọc Public Key từ Secret tên "cosign-pub-key" trong namespace "kyverno"
```

> **Mô hình Production Ready:** Thay vì fix cứng Public Key vào file YAML (rất khó để quản lý và xoay vòng khóa), ta nên lưu nó vào Kubernetes Secret. Kyverno sẽ tự động tra cứu Secret này để lấy khóa xác minh.
> 
> ```bash
> # Lệnh tạo Secret từ file cosign.pub
> kubectl create secret generic cosign-pub-key -n kyverno --from-file=cosign.pub=cosign.pub
> ```

Khi policy này được apply:
1. Bất kỳ lệnh `kubectl apply` nào tạo Pod sử dụng `my-repo/*`.
2. Kyverno sẽ bắt request, tải chữ ký từ Registry.
3. Kyverno sẽ lấy Public Key từ Secret `cosign-pub-key` (namespace `kyverno`) để xác minh.
4. Nếu khớp: Cho phép Pod tạo ra. Nếu sai/không có chữ ký: Request bị Deny ngay lập tức.
