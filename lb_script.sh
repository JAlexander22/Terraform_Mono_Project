#!/bin/bash
# Update packages and install NGINX
sudo apt-get update -y
sudo apt-get install -y nginx

# Configure NGINX to load balance traffic to the two app instances
cat << 'EOL' | sudo tee /etc/nginx/sites-available/default
upstream app_servers {
server ${aws_instance.app_instance.*.private_ip[0]}:80;
server ${aws_instance.app_instance.*.private_ip[1]}:80;
}

server {
listen 80;
location / {
proxy_pass http://127.0.0.1:8000;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
 }
}
EOL

# Restart NGINX to apply the configuration
sudo systemctl restart nginx
EOF