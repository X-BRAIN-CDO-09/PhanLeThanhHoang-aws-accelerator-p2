#!/bin/bash

echo -e "\e[32mĐang dọn dẹp các tiến trình port-forward cũ (nếu có)...\e[0m"
pkill kubectl || true
sleep 2

echo -e "\e[32mĐang khởi động tất cả giao diện...\e[0m"

echo "🔗 Flipkart (App): http://127.0.0.1:3000"
kubectl -n flipkart port-forward svc/flipkart-frontend 3000:80 --address 127.0.0.1 >logs/flipkart.log 2>&1 &

echo "🔗 Grafana (Dashboard): http://127.0.0.1:3001"
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3001:80 --address 127.0.0.1 >logs/grafana.log 2>&1 &

echo "🔗 Prometheus (Metrics): http://127.0.0.1:9090"
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090 --address 127.0.0.1 >logs/prometheus.log 2>&1 &

echo "🔗 AlertManager (Alerts): http://127.0.0.1:9093"
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 --address 127.0.0.1 >logs/alertmanager.log 2>&1 &

echo "🔗 Argo Rollouts (Canary): http://localhost:3100"
kubectl argo rollouts dashboard -p 3100 >logs/rollouts-dashboard.log 2>&1 &

echo -e "\e[33m[ Đang giữ kết nối. Bấm Ctrl + C để dừng tất cả ]\e[0m"

# Lệnh wait này sẽ giữ cho script không bị thoát, từ đó bảo vệ các tiến trình ngầm
wait
