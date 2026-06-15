#!/bin/bash

echo "1. Cài đặt OPA Gatekeeper (nếu cụm của bạn chưa cài)..."
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

echo "Lưu ý: Nếu mới cài đặt Gatekeeper, bạn cần đợi một chút để các Pod của Gatekeeper chuyển sang trạng thái Running."
echo "Bạn có thể kiểm tra bằng lệnh: kubectl get pods -n gatekeeper-system"
echo "----------------------------------------"

echo "2. Áp dụng file Template và Constraint..."
kubectl apply -f bai-2-gatekeeper.yaml

echo "Chờ vài giây để Webhook của Gatekeeper cập nhật policy mới..."
sleep 5

echo "--- BẮT ĐẦU KIỂM TRA ---"

echo -e "\n[Kịch bản 1]: Thử tạo Namespace KHÔNG có label 'owner'"
echo "KẾT QUẢ MONG ĐỢI: Bị từ chối (Error from server... denied by must-have-owner)"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: test-ns-no-label
EOF

echo -e "\n----------------------------------------"
echo -e "\n[Kịch bản 2]: Thử tạo Namespace CÓ label 'owner: team-a'"
echo "KẾT QUẢ MONG ĐỢI: Thành công (namespace/test-ns-with-label created)"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: test-ns-with-label
  labels:
    owner: "team-a"
EOF

echo -e "\n----------------------------------------"
echo "Dọn dẹp môi trường test..."
kubectl delete ns test-ns-with-label --ignore-not-found
