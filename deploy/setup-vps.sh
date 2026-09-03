#!/usr/bin/env bash
# ==============================================================================
# TheNexopp Agent - Master VPS Setup & Deployment Script
# Target OS: Ubuntu 22.04 / 24.04 LTS (Hostinger VPS)
# ==============================================================================

set -e

echo "🚀 Starting TheNexopp Agent Production VPS Setup..."

# 1. Update system packages
echo "📦 Updating apt packages..."
apt-get update -y && apt-get upgrade -y
apt-get install -y curl git nginx ufw build-essential unzip sqlite3

# 2. Install Node.js 20 LTS
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js 20 LTS..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi

# 3. Install PM2 process manager
echo "⚡ Installing PM2..."
npm install -g pm2

# 4. Create App Directory structure
echo "📁 Setting up /var/www/thenexopp..."
mkdir -p /var/www/thenexopp
mkdir -p /var/www/thenexopp/backend/uploads/private-kyc
mkdir -p /var/www/thenexopp/backend/uploads/property-images
mkdir -p /var/www/thenexopp/backend/uploads/payment-proofs
mkdir -p /var/www/thenexopp/backend/uploads/common

# Grant read/write permissions for uploads
chmod -R 777 /var/www/thenexopp/backend/uploads

# 5. Build and deploy Backend
echo "🔨 Building Backend API & WebSocket Server..."
cd /var/www/thenexopp/backend
npm install
npm run build

# 6. Build and deploy Admin Portal
echo "🔨 Building Admin Management Portal..."
cd /var/www/thenexopp/admin
npm install
npm run build

# 7. Configure Nginx Reverse Proxy
echo "🌐 Configuring Nginx..."
cp /var/www/thenexopp/deploy/nginx-thenexopp.conf /etc/nginx/sites-available/thenexopp
ln -sf /etc/nginx/sites-available/thenexopp /etc/nginx/sites-enabled/thenexopp
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
systemctl enable nginx

# 8. Start Backend with PM2
echo "⚡ Starting PM2 Services..."
cd /var/www/thenexopp/backend
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup systemd -u root --hp /root || true

# 9. Configure Firewall (UFW)
echo "🛡️ Configuring Firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 3001/tcp
ufw allow 8080/tcp
ufw --force enable

echo "=============================================================================="
echo "🎉 DEPLOYMENT COMPLETE! All services are active and running:"
echo "👉 Mobile Agent App:    http://$(curl -s ifconfig.me)/"
echo "👉 Admin Management:    http://$(curl -s ifconfig.me):3001  (or http://$(curl -s ifconfig.me)/admin)"
echo "👉 Backend REST API:    http://$(curl -s ifconfig.me)/api/v1"
echo "👉 WebSocket Gateway:   ws://$(curl -s ifconfig.me)/ws"
echo "👉 Uploads Storage:     /var/www/thenexopp/backend/uploads"
echo "=============================================================================="
