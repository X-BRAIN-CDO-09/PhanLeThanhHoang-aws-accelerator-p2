# CÁC BƯỚC XÓA VÀ CHẠY LẠI TỪ ĐẦU (FRESH START)

Chỉ cần chạy tuần tự các lệnh dưới đây trong Terminal (đảm bảo đang ở thư mục `cloud/w9/flipkart`):

## BƯỚC 1: Xóa cụm cũ
```bash
minikube delete -p w9
```

## BƯỚC 2: Dựng lại toàn bộ hệ thống
```bash
./run-labs.sh
```
*(Chờ khoảng 5-7 phút cho đến khi lệnh chạy xong 100% và in ra các đường link).*

## BƯỚC 3: Nạp Secret cho AlertManager
Ngay sau khi lệnh trên chạy xong, chạy tiếp:
```bash
./setup-sealed-secrets.sh
```
*(Dán API Key SendGrid của bạn vào khi được hỏi).*

## BƯỚC 4: Mở giao diện và Giả lập khách truy cập

Mở **Tab Terminal số 2**, di chuyển vào `cloud/w9/flipkart` và chạy lệnh nối mạng:
```bash
./port-forward.sh
```

Mở **Tab Terminal số 3**, chạy lệnh tạo lượng truy cập giả (nhớ để nó chạy liên tục không tắt):
```bash
while true; do curl -s http://127.0.0.1:3000/api/v1/products >/dev/null; echo -n "."; sleep 0.5; done
```

## BƯỚC 5: Thực hiện Test và Chụp ảnh
Mở file `TESTING-GUIDE.md` và làm y chang theo kịch bản trong đó để lấy 9 tấm ảnh. Tỷ lệ thành công là 100%!
