# CI/CD với GitHub Actions: Plan on PR, Apply on Merge

## 1. CI/CD trong Quản lý Hạ tầng (Infrastructure as Code)
Trong môi trường DevOps/Cloud hiện đại, việc quản lý hạ tầng (Terraform) nên tuân theo luồng CI/CD tương tự như phát triển phần mềm. Chúng ta sử dụng GitHub Actions để tự động hóa quy trình này:
- **Plan on Pull Request (PR):** Khi có một thay đổi hạ tầng được đề xuất qua PR, hệ thống tự động chạy `terraform plan` để xem trước những thay đổi. Điều này giúp team review PR biết chính xác những gì sẽ được tạo, sửa, hoặc xóa.
- **Apply on Merge (Main branch):** Khi PR được phê duyệt và merge vào nhánh `main`, hệ thống tự động chạy `terraform apply` để áp dụng những thay đổi đó vào môi trường thực tế.

## 2. Lợi ích
- **Minh bạch (Visibility):** Tất cả các thành viên đều thấy được tác động của thay đổi qua log của `terraform plan` trên PR.
- **An toàn (Safety):** Ngăn chặn việc apply các thay đổi chưa được review, giảm rủi ro lỗi do con người (manual apply ở local).
- **Auditability:** Lịch sử GitHub và GitHub Actions log cung cấp audit trail rõ ràng về việc ai đã thay đổi gì, khi nào.

## 3. Ví dụ Workflow GitHub Actions

### Plan on PR (VD: `.github/workflows/tf-plan.yml`)
```yaml
name: "Terraform Plan"
on:
  pull_request:
    paths:
      - 'terraform/**'
jobs:
  terraform:
    name: "Terraform Plan"
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repo
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color
        working-directory: ./terraform
        continue-on-error: true
```

### Apply on Merge (VD: `.github/workflows/tf-apply.yml`)
```yaml
name: "Terraform Apply"
on:
  push:
    branches:
      - main
    paths:
      - 'terraform/**'
jobs:
  terraform:
    name: "Terraform Apply"
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repo
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform
```

*(Lưu ý: Bạn sẽ cần cấu hình OIDC hoặc AWS Credentials trong GitHub Actions để cấp quyền gọi AWS API).*
