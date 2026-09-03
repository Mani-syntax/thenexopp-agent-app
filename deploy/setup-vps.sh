#!/usr/bin/env bash
# ==============================================================================
# TheNexopp Agent - Master VPS Setup & Deployment Script
# Target: /opt/thenexopp-agent (Ubuntu 22.04 / 24.04 LTS)
# ==============================================================================

set -e

APP_DIR="/opt/thenexopp-agent"
echo "🚀 Starting TheNexopp Agent Production Setup in $APP_DIR..."

# 1. Update system packages
echo "📦 Updating apt packages..."
apt-get update -y
apt-get install -y curl git nginx ufw build-essential unzip sqlite3 dos2unix

# Clean line endings and BOMs
dos2unix $APP_DIR/deploy/* || true
sed -i '1s/^ï»¿//' $APP_DIR/deploy/nginx-thenexopp.conf || true

# 2. Install Node.js 20 LTS
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js 20 LTS..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi

# 3. Install PM2 process manager
echo "⚡ Installing PM2..."
npm install -g pm2

# 4. Create App Directory & Storage structure
echo "📁 Setting up persistent upload directories..."
mkdir -p "$APP_DIR/backend/uploads/private-kyc"
mkdir -p "$APP_DIR/backend/uploads/property-images"
mkdir -p "$APP_DIR/backend/uploads/payment-proofs"
mkdir -p "$APP_DIR/backend/uploads/common"

# Grant full read/write permissions for persistent uploads
chmod -R 777 "$APP_DIR/backend/uploads"

# 5. Build and deploy Backend
echo "🔨 Building Backend API & WebSocket Server..."
cd "$APP_DIR/backend"
npm install
npm run build

# 6. Build and deploy Admin Portal
echo "🔨 Building Admin Management Portal..."
cd "$APP_DIR/admin"
npm install
npm run build

# 6.5 Deploy Mobile App (Flutter Web)
echo "📱 Deploying Mobile Web App..."
mkdir -p "$APP_DIR/mobile/build/web"
if [ -f "$APP_DIR/deploy/mobile-web.tar.gz" ]; then
    tar -xzf "$APP_DIR/deploy/mobile-web.tar.gz" -C "$APP_DIR/mobile/build/web"
fi

# 7. Configure Nginx Reverse Proxy
echo "🌐 Configuring Nginx..."
cp "$APP_DIR/deploy/nginx-thenexopp.conf" /etc/nginx/sites-available/thenexopp
sed -i '1s/^ï»¿//' /etc/nginx/sites-available/thenexopp || true
dos2unix /etc/nginx/sites-available/thenexopp || true
ln -sf /etc/nginx/sites-available/thenexopp /etc/nginx/sites-enabled/thenexopp
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
systemctl enable nginx

# 8. Start Backend with PM2
echo "⚡ Starting PM2 Services..."
cd "$APP_DIR/backend"
pm2 delete thenexopp-backend || true
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
echo "👉 Uploads Storage:     $APP_DIR/backend/uploads"
echo "=============================================================================="
