# Day 2: Secrets Rotation + Supply Chain Security

## Mục tiêu
- Áp dụng AWS Secrets Manager + External Secrets Operator (ESO).
- Tích hợp Trivy image scan trong CI.
- Cấu hình Cosign signing (keyless OIDC + key-based) và admission webhook verify signature.
- Quản lý Exception policy CVE.

## Thư mục
- `eso/`: Chứa các manifest cài đặt và cấu hình External Secrets Operator.
- `signing/`: Thực hành ký image với Cosign.
- `ci-trivy/`: Cấu hình pipeline CI với Trivy scan.
