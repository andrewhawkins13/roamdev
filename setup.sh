#!/bin/bash
set -e

echo "=== roamdev setup ==="

# Must run as root
if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash setup.sh"
  exit 1
fi

echo "[1/6] Creating user 'dev'..."
useradd -m -s /bin/bash dev 2>/dev/null || true
usermod -aG sudo dev
echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
mkdir -p /home/dev/.ssh
cp /root/.ssh/authorized_keys /home/dev/.ssh/
chown -R dev:dev /home/dev/.ssh
chmod 700 /home/dev/.ssh
chmod 600 /home/dev/.ssh/authorized_keys

echo "[2/6] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "[3/6] Installing system packages..."
apt-get update -qq
apt-get install -y -qq nginx tmux git curl wget build-essential

echo "[4/6] Installing Node.js..."
su - dev << 'EOF'
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
npm install -g @anthropic-ai/claude-code
mkdir -p ~/projects
EOF

echo "[5/6] Configuring Nginx..."
mkdir -p /var/www/dev
chown dev:dev /var/www/dev
echo '<h1>roamdev ready</h1>' > /var/www/dev/index.html

cat > /etc/nginx/sites-available/dev << 'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/dev;
    index index.html;
    server_name _;
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/dev /etc/nginx/sites-enabled/dev
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "[6/6] Starting Tailscale..."
echo ""
echo "============================================"
echo "Authenticate Tailscale by visiting the URL below:"
echo "============================================"
tailscale up

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Tailscale IP: $(tailscale ip -4)"
echo ""
echo "Connect with: ssh dev@$(tailscale ip -4)"
echo ""
