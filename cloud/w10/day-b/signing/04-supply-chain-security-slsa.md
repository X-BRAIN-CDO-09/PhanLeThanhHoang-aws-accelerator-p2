# Bảo mật chuỗi cung ứng phần mềm (Supply Chain Security) & SLSA

## 1. Software Supply Chain Security là gì?
Chuỗi cung ứng phần mềm (Software Supply Chain) bao gồm toàn bộ quá trình, công cụ, con người và mã nguồn liên quan đến việc sản xuất một ứng dụng. Từ lúc dev gõ code, commit lên Git, CI/CD build, các thư viện (dependencies) được kéo về, cho tới lúc ứng dụng chạy trên K8s.

Tấn công vào chuỗi cung ứng (như vụ SolarWinds năm 2020) xảy ra khi tin tặc chèn mã độc vào một thư viện mã nguồn mở phổ biến, hoặc xâm nhập vào hệ thống CI/CD để thay đổi bản build cuối cùng.

## 2. SBOM - Software Bill of Materials
**SBOM** giống như bảng thành phần dinh dưỡng trên hộp sữa. Nó là một tệp (thường là định dạng JSON như SPDX hoặc CycloneDX) liệt kê TẤT CẢ các thư viện mã nguồn mở, phiên bản, giấy phép... mà phần mềm của bạn đang sử dụng.

Công dụng:
- Nếu một lỗi Zero-day mới xuất hiện (ví dụ Log4j), thay vì đi quét lại toàn bộ hệ thống, bạn chỉ cần tra cứu tập tin SBOM để biết ngay ứng dụng của mình có dùng thư viện lỗi đó hay không.
- *Công cụ:* Trivy, Syft có thể tự động sinh SBOM từ Docker image của bạn.

## 3. Khung tiêu chuẩn SLSA (Salsa)
**SLSA (Supply-chain Levels for Software Artifacts)** là một framework do Google và Linux Foundation phát triển để ngăn chặn việc giả mạo phần mềm. SLSA chia mức độ bảo mật thành các cấp (Level):

- **Level 1:** Build quá trình tự động (có script) và tạo ra **Provenance** (Giấy chứng nhận nguồn gốc - chứng minh artifact này sinh ra từ source code nào, bởi builder nào).
- **Level 2:** Yêu cầu dùng hệ thống quản lý source code (Git), build phải diễn ra trên một dịch vụ Hosted (như GitHub Actions, thay vì build tay trên máy dev).
- **Level 3:** Môi trường build phải bị cô lập (Isolated), không thể bị can thiệp bởi các bước build khác. Provenance không thể bị làm giả.
- **Level 4:** Yêu cầu 2-person review code, các bước build khép kín hoàn toàn (Hermetic).

## 4. Tổng hợp chiến lược bảo vệ chuỗi cung ứng
1. **Source:** Kích hoạt tính năng Branch Protection, yêu cầu review code. Ký commit bằng GPG.
2. **Build:** Dùng môi trường CI/CD dùng một lần (ephemeral). Không dùng key tĩnh. Quét mã nguồn tĩnh (SAST).
3. **Artifact:** Quét lỗ hổng image bằng Trivy. Tạo SBOM. Ký image bằng Cosign.
4. **Deploy:** Dùng GitOps. Áp dụng Admission Control (Gatekeeper/Kyverno) để từ chối chạy những image chưa được ký.
