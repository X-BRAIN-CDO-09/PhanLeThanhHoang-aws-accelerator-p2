# Thực hành 1: Thiết lập CI/CD cho Terraform bằng GitHub Actions

Trong bài tập này, chúng ta sẽ tạo 2 workflow trên GitHub Actions:
1. **Terraform Plan**: Chạy tự động khi có Pull Request (PR) mở vào nhánh `main`.
2. **Terraform Apply**: Chạy tự động khi PR được Merge vào nhánh `main`.

## Bước 1: Tạo thư mục chứa Workflows
Tại thư mục gốc (root) của dự án, tạo cấu trúc thư mục sau nếu chưa có:
```bash
mkdir -p .github/workflows
```

## Bước 2: Viết Workflow "Terraform Plan"
Tạo file `.github/workflows/tf-plan.yml` với nội dung sau:

```yaml
name: "Terraform Plan"

on:
  pull_request:
    branches:
      - main
    paths:
      - 'cloud/w9/sample_app/**' # Trỏ tới thư mục chứa code Terraform của bạn

jobs:
  terraform-plan:
    name: "Terraform Plan"
    runs-on: ubuntu-latest

    # Khai báo các biến môi trường cần thiết để xác thực AWS. 
    # Lưu ý: Cần thêm credentials vào GitHub Secrets (Repository Settings -> Secrets -> Actions)
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: "us-east-1" # Thay đổi region nếu cần

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Terraform Init
        run: terraform init
        working-directory: cloud/w9/sample_app

      - name: Terraform Format Check
        run: terraform fmt -check
        working-directory: cloud/w9/sample_app
        continue-on-error: true

      - name: Terraform Plan
        run: terraform plan -no-color
        working-directory: cloud/w9/sample_app
```

## Bước 3: Viết Workflow "Terraform Apply"
Tạo file `.github/workflows/tf-apply.yml` với nội dung sau:

```yaml
name: "Terraform Apply"

on:
  push:
    branches:
      - main
    paths:
      - 'cloud/w9/sample_app/**'

jobs:
  terraform-apply:
    name: "Terraform Apply"
    runs-on: ubuntu-latest
    
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: "us-east-1"

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Terraform Init
        run: terraform init
        working-directory: cloud/w9/sample_app

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: cloud/w9/sample_app
```

## Bước 4: Kiểm thử
1. Commit các thay đổi (chỉ lưu code lên một nhánh riêng, ví dụ `feature/ci-cd`).
2. Lên GitHub, tạo một Pull Request từ nhánh `feature/ci-cd` vào nhánh `main`.
3. Quan sát tab **Actions** trên GitHub, bạn sẽ thấy tiến trình "Terraform Plan" đang chạy. Mở log để xem chi tiết bản plan.
4. Nhấn nút **Merge PR**. Quan sát tab Actions một lần nữa, bạn sẽ thấy tiến trình "Terraform Apply" được tự động kích hoạt.
