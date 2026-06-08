# Chiến lược Rollback: git revert vs kubectl rollout undo

Khi một bản deploy mới bị lỗi, việc đưa hệ thống về trạng thái ổn định càng nhanh càng tốt là rất quan trọng. Trong môi trường GitOps, chúng ta có 2 cách chính để thực hiện.

## 1. The GitOps Way: `git revert` (Recommended)
Theo triết lý GitOps, Git là Single Source of Truth. Nếu trạng thái trên cluster sai, tức là code trên Git đang sai. Để sửa lỗi, ta cần sửa trên Git.

**Cách thực hiện:**
1. Mở Git repository, tạo một lệnh revert:
   `git revert <commit-hash-lỗi>`
2. Push lên branch chính hoặc tạo PR.
3. Khi PR được merge, code trên nhánh `main` quay về phiên bản trước.
4. ArgoCD phát hiện sự thay đổi, tiến hành Sync lại cluster về bản cũ.

**Ưu điểm:**
- Trạng thái trên cluster luôn đồng nhất (in-sync) với Git.
- Mọi lịch sử rollback đều được ghi nhận (Audit logs).

**Nhược điểm:**
- Có thể mất vài phút cho toàn bộ chu trình (Commit -> CI -> ArgoCD detect -> Sync), trong lúc đó user vẫn gặp lỗi.

## 2. The Imperative Way: `kubectl rollout undo` / ArgoCD UI Rollback
Đây là cách làm trực tiếp trên cluster, dùng lệnh imperative để "quay xe" khẩn cấp.

**Cách thực hiện:**
- Dùng lệnh CLI: `kubectl rollout undo deployment/my-app`
- Hoặc trên giao diện ArgoCD: Bấm nút `History and Rollback` -> Chọn bản revision trước đó và ấn Rollback. (Trong lúc này tạm thời vô hiệu hóa Auto-sync).

**Ưu điểm:**
- Rất nhanh, hệ thống ngay lập tức khởi tạo lại các pod cũ, giảm thiểu downtime.

**Nhược điểm:**
- Hệ thống bị lệch trạng thái (OutOfSync) với Git. 
- Nguy cơ "lấp liếm" vấn đề nếu sau khi rollback xong không ai sửa code trong Git, đến lần sau auto-sync, ArgoCD lại... đè bản lỗi ra lại.

## Best Practice
- Dùng **Argo Rollback / kubectl rollout undo** khi tình huống quá khẩn cấp và cần giải quyết incident tính bằng giây. Ngay lập tức sau đó, phải thực hiện `git revert` và bật lại Auto-sync.
- Dùng **git revert** cho các lỗi không quá nghiêm trọng, cần đảm bảo tính đúng đắn của toàn bộ luồng pipeline.
