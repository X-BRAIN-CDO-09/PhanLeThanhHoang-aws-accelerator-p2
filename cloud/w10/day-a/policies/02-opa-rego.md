# Open Policy Agent (OPA) và Ngôn ngữ Rego

## 1. OPA là gì?
**Open Policy Agent (OPA)** là một policy engine mã nguồn mở, cho phép bạn tách biệt logic kiểm soát truy cập và các quy tắc (policies) ra khỏi mã nguồn ứng dụng. 
Trong K8s, OPA thường được sử dụng để kiểm tra (validate) hoặc thay đổi (mutate) các request trước khi chúng được API Server chấp nhận.

## 2. Ngôn ngữ Rego
OPA sử dụng một ngôn ngữ khai báo chuyên biệt gọi là **Rego**. Rego được thiết kế để truy vấn và đánh giá dữ liệu JSON/YAML.

### Cú pháp cơ bản của Rego
Một policy trong Rego thường bao gồm các "Rule". Một rule trả về giá trị `true` hoặc `false` (hoặc tập hợp các chuỗi thông báo lỗi).

Ví dụ đơn giản:
```rego
package main

# Mặc định deny là false
default allow = false

# allow sẽ thành true nếu input.user == "admin"
allow {
    input.user == "admin"
}
```

### Ví dụ Rego cho Kubernetes (Kiểm tra Label)
Giả sử ta muốn chặn việc tạo Namespace nếu không có label `owner`:

```rego
package k8s.namespaces

# Định nghĩa rule 'violation', trả về thông báo lỗi nếu điều kiện bên trong đúng
violation[{"msg": msg}] {
    # 1. Kiểm tra đối tượng là Namespace
    input.review.object.kind == "Namespace"
    
    # 2. Lấy danh sách labels (nếu không có thì mặc định là rỗng)
    provided_labels := {label | input.review.object.metadata.labels[label]}
    
    # 3. Kiểm tra xem "owner" có nằm trong danh sách labels không
    not provided_labels["owner"]
    
    # 4. Trả về câu thông báo lỗi
    msg := "Mọi Namespace phải có label 'owner'"
}
```

## 3. Cách Rego hoạt động trong OPA
- Khi có một request gửi tới (ví dụ: `kubectl create namespace test`), K8s sẽ gói request đó thành một JSON object (`AdmissionReview`) và gửi cho OPA.
- JSON object này chính là biến `input` trong đoạn code Rego.
- OPA chạy các rule Rego dựa trên `input` này.
- Nếu rule `violation` sinh ra bất kỳ message nào, OPA sẽ trả về phản hồi "Deny" cho K8s kèm thông báo lỗi đó.

## 4. Công cụ học tập
- Để thử nghiệm viết và chạy Rego trực tiếp trên trình duyệt, bạn có thể truy cập: **[Rego Playground](https://play.openpolicyagent.org/)**.
