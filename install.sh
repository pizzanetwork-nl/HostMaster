#!/bin/bash
set -euo pipefail

echo "=== HostMaster All-in-One Installer ==="

# --- 1) Prompts ---
read -p "Domein voor website (bv example.com): " PUBLIC_DOMAIN
read -p "Email voor SSL (bv admin@example.com): " SSL_EMAIL
read -p "API key voor interne API (x-api-key): " API_KEY
read -p "Stripe Secret Key (sk_...): " STRIPE_SECRET
read -p "Stripe Webhook Secret (whsec_...): " STRIPE_WEBHOOK_SECRET
read -p "Stripe Public Key (pk_...): " STRIPE_PUBLIC_KEY
read -p "Echte libvirt provisioning gebruiken? (ja/nee): " USE_LIBVIRT

if [[ "${USE_LIBVIRT,,}" == "ja" ]]; then
  read -p "Hypervisor SSH host (IP): " HV_HOST
  read -p "Hypervisor SSH user (bv root): " HV_USER
  read -p "Pad naar SSH private key (bv /root/.ssh/id_rsa): " HV_KEYPATH
else
  HV_HOST=""
  HV_USER=""
  HV_KEYPATH=""
fi

# --- 2) Systeem update & vereisten ---
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y
apt install -y git curl docker.io docker-compose nginx ufw certbot python3-certbot-nginx

# --- 3) Firewall ---
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# --- 4) Clone repo ---
BASE="/opt/hostmaster"
REPO_URL="https://github.com/<GITHUB_USER>/HostMaster.git"
rm -rf "$BASE"
mkdir -p "$BASE"
chown "$(whoami):$(whoami)" "$BASE"
git clone "$REPO_URL" "$BASE"
cd "$BASE"

# --- 5) Schrijf .env bestanden ---
mkdir -p backend frontend/hostmaster frontend/pterolite

cat > backend/.env <<EOL
PORT=3000
DATABASE_URL=postgresql://postgres:postgres@db:5432/hostmaster
REDIS_URL=redis://redis:6379
STRIPE_SECRET=${STRIPE_SECRET}
STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}
PUBLIC_URL=https://${PUBLIC_DOMAIN}
API_KEY=${API_KEY}
USE_LIBVIRT=${USE_LIBVIRT}
HV_HOST=${HV_HOST}
HV_USER=${HV_USER}
HV_KEYPATH=${HV_KEYPATH}
SECRET_KEY=$(head -c 32 /dev/urandom | base64)
EOL

cat > frontend/hostmaster/.env <<EOL
VITE_STRIPE_PUBLIC_KEY=${STRIPE_PUBLIC_KEY}
VITE_PUBLIC_URL=https://${PUBLIC_DOMAIN}
EOL

cat > frontend/pterolite/.env <<EOL
VITE_PUBLIC_URL=https://${PUBLIC_DOMAIN}
EOL

# --- 6) Docker-compose.yml ---
cat > docker-compose.yml <<'YAML'
version: '3.8'
services:
  backend:
    build: ./backend
    env_file:
      - ./backend/.env
    volumes:
      - ./backend:/app
    depends_on:
      - db
      - redis
    ports:
      - "3000:3000"

  hostmaster-frontend:
    build: ./frontend/hostmaster
    depends_on:
      - backend
    ports:
      - "8080:80"

  pterolite-frontend:
    build: ./frontend/pterolite
    depends_on:
      - backend
    ports:
      - "8081:80"

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: hostmaster
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:7

volumes:
  db_data:
YAML

# --- 7) Containers bouwen en starten ---
docker-compose up -d --build
sleep 8

# --- 8) Seed database ---
if [ -f backend/src/scripts/run_seed.js ]; then
  docker-compose exec -T backend node src/scripts/run_seed.js || true
fi

# --- 9) Nginx setup ---
NGINX_CONF="/etc/nginx/sites-available/hostmaster"
sudo tee "$NGINX_CONF" > /dev/null <<EOL
server {
    listen 80;
    server_name ${PUBLIC_DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /pterolite/ {
        proxy_pass http://127.0.0.1:8081/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /api/webhook {
        proxy_pass http://127.0.0.1:3000/api/webhook;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/hostmaster
sudo nginx -t
sudo systemctl reload nginx

# --- 10) SSL ---
certbot --nginx -d "${PUBLIC_DOMAIN}" --non-interactive --agree-tos -m "${SSL_EMAIL}"

# --- 11) systemd backend service ---
sudo tee /etc/systemd/system/hostmaster-backend.service > /dev/null <<EOL
[Unit]
Description=HostMaster backend (docker-compose)
Requires=docker.service
After=docker.service

[Service]
WorkingDirectory=${BASE}
ExecStart=/usr/bin/docker-compose up backend
ExecStop=/usr/bin/docker-compose down
Restart=always
Environment=COMPOSE_HTTP_TIMEOUT=200

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable hostmaster-backend
sudo systemctl start hostmaster-backend

# --- 12) Worker starten ---
docker-compose exec -T backend sh -c "nohup node src/worker.js > /proc/1/fd/1 2>/proc/1/fd/2 &" || true

# --- 13) Eindmelding ---
echo
echo "Installatie voltooid!"
echo "Frontend (HostMaster): https://${PUBLIC_DOMAIN}"
echo "PteroLite: https://${PUBLIC_DOMAIN}/pterolite"
echo "Backend API: https://${PUBLIC_DOMAIN}/api"
echo "Stripe webhook: https://${PUBLIC_DOMAIN}/api/webhook"
echo "API key: ${API_KEY}"
