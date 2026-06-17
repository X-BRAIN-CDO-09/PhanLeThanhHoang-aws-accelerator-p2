# HƯỚNG DẪN LẤY 9 BẰNG CHỨNG (EVIDENCE) CHO BÀI LAB CANARY

Mọi thứ đã được tự động hóa và chạy trơn tru. Bây giờ bạn chỉ việc làm theo đúng kịch bản dưới đây như một đạo diễn để thu thập đủ 9 tấm ảnh báo cáo nhé!

*(Đảm bảo bạn đang chạy `./port-forward.sh` ở một tab WSL riêng để giữ các đường link luôn sống).*

---

## GIAI ĐOẠN 1: CHỤP ẢNH HỆ THỐNG ĐANG KHOẺ MẠNH

**📸 Ảnh 1: `01-argocd-applications-healthy.png`**
1. Mở link: [https://127.0.0.1:8080](https://127.0.0.1:8080) (Đăng nhập: `admin` / Password lấy ở cuối màn hình chạy lệnh `run-labs.sh`).
2. Chụp màn hình toàn bộ các App (`root`, `flipkart-backend`, `kube-prometheus-stack`...) đều đang có trái tim xanh lá cây (`Healthy` và `Synced`).

**📸 Ảnh 2: `02-prometheus-backend-target-up.png`**
1. Mở link: [http://127.0.0.1:9090](http://127.0.0.1:9090)
2. Nhìn lên menu trên cùng, bấm **Status** -> **Targets**.
3. Cuộn xuống tìm mục `serviceMonitor/flipkart/flipkart-backend/0`.
4. Chụp màn hình cho thấy nó đang hiển thị chữ `UP` màu xanh lá.

**📸 Ảnh 3: `03-prometheus-sli-queries.png`**
1. Mở link: [http://127.0.0.1:3001](http://127.0.0.1:3001) (Grafana - Đăng nhập: `admin` / `prom-operator`).
2. Vào **Explore** (Biểu tượng la bàn bên trái), chọn Data source là Prometheus.
3. Nhập câu Query sau vào ô tìm kiếm: `sum(rate(http_request_duration_seconds_count{namespace="flipkart"}[2m]))` và bấm Run query.
4. Chụp màn hình biểu đồ đang có các đường chỉ số (hoặc chụp bên Prometheus [9090] bằng tab Graph cũng được).

---

## GIAI ĐOẠN 2: DIỄN TẬP PHÁT HÀNH BẢN LỖI (BAD RELEASE) & AUTO-ABORT

Bây giờ chúng ta sẽ cố tình đẩy một bản code bị lỗi (Error Rate = 50%) lên Git để xem Argo Rollouts tự động phát hiện và huỷ bỏ (Abort) như thế nào.

**Thao tác kích hoạt:**
Mở file `cloud/w9/flipkart/k8s/backend/rollout.yaml` trên VSCode của bạn. Tìm đến dòng 31:
```yaml
          env:
            - name: ERROR_RATE
              value: "0.5"    # SỬA TỪ "0" THÀNH "0.5"
            - name: VERSION
              value: "v2-bad" # SỬA TỪ "v1" THÀNH "v2-bad"
```
Lưu file lại, sau đó dùng Terminal (WSL) đẩy lên Git:
```bash
git add cloud/w9/flipkart/k8s/backend/rollout.yaml
git commit -m "[Bad Release] Update version v2-bad with 50% errors"
git push origin main
```

Ngay sau khi gõ xong lệnh Push, hãy lập tức mở trang Argo Rollouts: [http://localhost:3100/rollouts](http://localhost:3100/rollouts) và ngắm nhìn nó biểu diễn!

**📸 Ảnh 6: `06-manual-canary-paused-25.png`**
- Trên trang Rollouts (3100), bạn sẽ thấy nó tạo ra một nhánh màu vàng/xanh mới (bản v2-bad) và thanh tiến trình dừng lại ở mức `10%` hoặc `50%` (Paused). Hãy chụp màn hình lúc nó đang tạm dừng (Paused) này!

**📸 Ảnh 4: `04-slo-alert-firing.png`**
- Mở trang AlertManager: [http://127.0.0.1:9093](http://127.0.0.1:9093) (hoặc trang Prometheus 9090 tab Alerts).
- Sau khoảng 1-2 phút, bạn sẽ thấy cảnh báo `HighErrorRate` hiện lên màu Đỏ (`FIRING`). Chụp màn hình này lại!

**📸 Ảnh 5: `05-alert-email.png`**
- Mở hòm thư Gmail `ringhost42@gmail.com` của bạn, bạn sẽ nhận được một email cảnh báo hệ thống đang lỗi từ AlertManager. Chụp màn hình email đó!

**📸 Ảnh 8: `08-bad-release-auto-abort.png`**
- Quay lại trang Argo Rollouts (3100). Sau vài phút phân tích, AnalysisRun sẽ đánh trượt bản v2-bad (vì lỗi nhiều quá).
- Bạn sẽ thấy nhánh v2-bad bị gạch chéo đỏ, hiện chữ `Degraded` hoặc `Aborted` và mũi tên dồn 100% traffic về lại bản `v1` cũ. Chụp màn hình chiến tích tự động bảo vệ hệ thống này!

---

## GIAI ĐOẠN 3: ROLLBACK LẠI BẰNG GIT

Sau khi bản lỗi bị tự động Abort, hệ thống vẫn an toàn, nhưng trên Git của bạn code vẫn đang là bản lỗi. Chúng ta phải dùng Git Revert để khôi phục chân lý.

**Thao tác kích hoạt:**
Gõ lệnh sau vào Terminal:
```bash
# Lệnh này sẽ tạo ra một commit đảo ngược lại cái commit Bad Release lúc nãy
git revert HEAD --no-edit
git push origin main
```

**📸 Ảnh 9: `09-git-revert-under-5-minutes.png`**
1. Chụp màn hình Terminal có lệnh `git revert` và `git push` thành công.
2. Mở lại ArgoCD (8080), thấy nó tự động Sync về lại bản cũ xanh mượt. Thời gian từ lúc Abort đến lúc Rollback xong chắc chắn dưới 5 phút!

---

## GIAI ĐOẠN 4: DIỄN TẬP PHÁT HÀNH BẢN TỐT (GOOD RELEASE)

Cuối cùng, đẩy một bản nâng cấp xịn xò không có lỗi lên để xem nó được tự động Promote (đưa lên 100%) như thế nào.

**Thao tác kích hoạt:**
Mở lại file `k8s/backend/rollout.yaml`. Sửa lại:
```yaml
          env:
            - name: ERROR_RATE
              value: "0"         # VỀ LẠI 0
            - name: VERSION
              value: "v2-good"   # ĐỔI THÀNH v2-good
```
Đẩy lên Git:
```bash
git add cloud/w9/flipkart/k8s/backend/rollout.yaml
git commit -m "[Good Release] Update version v2-good with 0% errors"
git push origin main
```

**📸 Ảnh 7: `07-good-release-analysis-success.png`**
- Lại mở trang Argo Rollouts (3100) và xem.
- Lần này AnalysisRun sẽ chạy, thấy tỷ lệ lỗi = 0% nên nó sẽ tick xanh lá (Successful).
- Thanh tiến trình sẽ tự động chạy mượt mà lên `100%` và bản `v2-good` trở thành bản chính thức (Stable). Chụp màn hình lúc nó đã xanh mượt 100% bản mới này!

---
*Chúc mừng bạn! Bạn đã hoàn thành 100% bài Lab cực kỳ phức tạp này. Nhớ lưu đủ 9 file ảnh và nộp bài nhé!*
