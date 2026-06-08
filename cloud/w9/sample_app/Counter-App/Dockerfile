# Sử dụng Nginx làm web server nhẹ
FROM nginx:alpine

# Copy code của bạn vào thư mục mặc định của Nginx
COPY index.html /usr/share/nginx/html/
COPY main.css /usr/share/nginx/html/
COPY index.js /usr/share/nginx/html/

# Expose port 80
EXPOSE 80