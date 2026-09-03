#!/usr/bin/env bash
# ==============================================================================
# TheNexopp Agent - Quick Update & Redeploy Script
# ==============================================================================

set -e

echo "🔄 Pulling latest updates..."
cd /var/www/thenexopp
git pull origin main || git pull

# 1. Update Backend
echo "🔨 Updating Backend..."
cd /var/www/thenexopp/backend
npm install
npm run build
pm2 restart thenexopp-backend --update-env

# 2. Update Admin Portal
echo "🔨 Updating Admin Portal..."
cd /var/www/thenexopp/admin
npm install
npm run build

# 3. Reload Nginx
nginx -t && systemctl reload nginx

echo "✅ All services updated and running smoothly!"
