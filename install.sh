#!/bin/bash
set -e
# ... [zoals eerder, inclusief prompts voor alle keys] ...

# Frontend .env
cat > frontend/.env <<EOL
VITE_STRIPE_PUBLIC_KEY=$STRIPE_PUBLIC_KEY
VITE_PUBLIC_URL=https://$PUBLIC_DOMAIN
EOL

# Docker Compose build en up
sudo docker-compose up -d --build

# Database seeds
sudo docker-compose exec backend node src/scripts/run_seed.js
