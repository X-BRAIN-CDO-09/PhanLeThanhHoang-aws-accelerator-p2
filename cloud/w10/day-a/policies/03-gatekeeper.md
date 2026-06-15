# OPA Gatekeeper

## 1. Gatekeeper là gì?
**Gatekeeper** là một dự án mở rộng của OPA được thiết kế riêng cho Kubernetes. Nó hoạt động như một **Validating Admission Webhook** trong Kubernetes.

Khi bạn sử dụng Gatekeeper, bạn không cần phải tự cấu hình webhook server cho OPA. Gatekeeper cung cấp các Custom Resource Definitions (CRDs) giúp bạn triển khai policy bằng định dạng chuẩn của K8s.

## 2. Kiến trúc của Gatekeeper
Gatekeeper chia policy thành 2 thành phần chính để tăng tính tái sử dụng:
1. **ConstraintTemplate:** Định nghĩa _logic Rego_ và lược đồ _tham số đầu vào_. Nó đóng vai trò như một hàm (function).
2. **Constraint:** Là một instance (thực thể) của ConstraintTemplate, nơi bạn truyền các _tham số cụ thể_ và chỉ định _phạm vi áp dụng_ (ví dụ: chỉ áp dụng cho Namespace, hoặc chỉ áp dụng cho Pod).

## 3. Ví dụ cấu hình

### Bước 1: Viết ConstraintTemplate
Template này yêu cầu mọi tài nguyên phải có những labels cụ thể.

```yaml
apiVersion: templates.gatekeeper.sh/v1 # Khai báo phiên bản API của Gatekeeper
kind: ConstraintTemplate               # Loại tài nguyên là ConstraintTemplate (Khuôn đúc)
metadata:
  name: k8srequiredlabels              # Tên của template này (tên phải viết thường, thường trùng với tên package trong Rego)
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels        # Gatekeeper sẽ tạo ra một K8s CRD mới có kind là K8sRequiredLabels
      validation:
        openAPIV3Schema:               # Khai báo cấu trúc dữ liệu đầu vào (các tham số)
          type: object                 # Tham số đầu vào sẽ là một Object
          properties:                  
            labels:                    # Object này có thuộc tính tên là "labels"
              type: array              # Kiểu dữ liệu của "labels" là một mảng (danh sách)
              items:                   
                type: string           # Mỗi phần tử trong mảng là một chuỗi (string)
  targets:
    - target: admission.k8s.gatekeeper.sh # Chỉ định mục tiêu áp dụng là Admission Webhook
      rego: |                             # Bắt đầu khối code Rego
        package k8srequiredlabels         # Tên package, bắt buộc phải giống tên ConstraintTemplate

        # Định nghĩa rule 'violation'. Nếu logic bên trong đúng, nó sẽ trả về 'msg' và 'details' (báo lỗi)
        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          
          # 1. Lấy danh sách các label ĐANG CÓ trên tài nguyên (Pod, Namespace...)
          provided := {label | input.review.object.metadata.labels[label]}
          
          # 2. Lấy danh sách các label BẮT BUỘC PHẢI CÓ mà người dùng đã truyền vào (từ tham số 'labels')
          required := {label | label := input.parameters.labels[_]}
          
          # 3. Lấy tập hợp 'bắt buộc' trừ đi tập hợp 'đang có' -> Ra danh sách các label bị thiếu
          missing := required - provided
          
          # 4. Kiểm tra điều kiện: Nếu có nhãn bị thiếu (số lượng > 0)
          count(missing) > 0
          
          # 5. Tạo ra câu thông báo lỗi (msg) chèn các nhãn bị thiếu vào. Rule violation kích hoạt và chặn tài nguyên.
          msg := sprintf("Bạn phải cung cấp các label sau: %v", [missing])
        }
```

### Bước 2: Viết Constraint
Áp dụng template trên, bắt buộc mọi **Namespace** phải có label `owner`.

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels # Tên kind này được sinh ra từ ConstraintTemplate
metadata:
  name: must-have-owner
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["owner"] # Truyền tham số cho Rego code
```

## 4. Tại sao nên dùng Gatekeeper?
- **Native K8s Experience:** Cấu hình bằng YAML giống các tài nguyên K8s khác.
- **Audit:** Gatekeeper không chỉ chặn các hành động mới, mà còn liên tục quét các tài nguyên ĐÃ TỒN TẠI trong cluster để phát hiện xem có ai vi phạm policy hay không.
