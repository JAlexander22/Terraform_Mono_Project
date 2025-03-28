#!/bin/bash

# Update the package list
sudo apt-get update -y
sudo apt-get install python3.12 -y
sudo apt install python3-pip -y
sudo apt install python3-venv -y
sudo apt-get install nginx -y
export PUBLIC_IP=$(curl -s ifconfig.me)
sleep 5

# Install dependencies
sudo apt-get install -y curl git gh

# Install GitHub CLI
echo "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo apt-get install apt-transport-https
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Update and install GitHub CLI
sudo apt-get install gh -y

# Install Git if not already installed
sudo apt-get install git -y


# Clone your GitHub repository
git clone https://github.com/JAlexander22/Flask_APP.git /home/ubuntu/JordanRepo

# Navigate to the repository directory

cd /home/ubuntu/JordanRepo/Flask_Website
sudo python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 wsgi:app --daemon



sudo unlink /etc/nginx/sites-enabled/default
cat << 'EOL' | sudo tee /etc/nginx/sites-available/flask_app
server {
    listen 80;
    server_name $PUBLIC_IP;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

EOL

sudo ln -s /etc/nginx/sites-available/flask_app /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx
# python app.py
