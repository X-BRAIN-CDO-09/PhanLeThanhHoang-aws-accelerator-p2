# Day 1: RBAC + Admission Policy (OPA/Gatekeeper)

## Mục tiêu
- Hiểu và áp dụng RBAC role/rolebinding/clusterrole, service account.
- Kiểm tra quyền với `kubectl auth can-i`.
- Hiểu và viết policy với OPA Rego.
- Phân biệt và sử dụng Gatekeeper constraint template vs constraint.
- Áp dụng ValidatingAdmissionPolicy native (K8s 1.30+), hiểu audit mode vs enforce.

## Thư mục
- `rbac/`: Chứa các file YAML thực hành RBAC.
- `policies/`: Chứa các policy OPA/Gatekeeper.
