# roamdev

Code from your phone. A $5/month cloud dev environment with AI coding agents.

```
iPhone/iPad ──> Tailscale ──> Hetzner VM ──> Claude Code
     │                            │
     └──── Browser ───────────────┘
                (live preview)
```

## What You Get

- SSH into a cloud VM from your phone
- Run Claude Code (or Cursor CLI, Gemini CLI) to build projects
- Preview your work in a browser instantly
- Works from any device (phone, tablet, laptop)

## Prerequisites

- [Hetzner Cloud account](https://www.hetzner.com/cloud)
- [Tailscale account](https://tailscale.com) (free)
- SSH client on your phone ([Termius](https://termius.com), [Blink Shell](https://blink.sh))
- Tailscale app on your phone

## Setup

### 1. Create the Server

In [Hetzner Cloud Console](https://console.hetzner.cloud):

1. Create a new project
2. Add your SSH key (from `~/.ssh/id_rsa.pub` on your computer)
3. Create a server:
   - **Image:** Ubuntu 24.04
   - **Type:** CPX11 (~$5/mo)
   - **Location:** Nearest to you
   - **SSH Key:** Select yours

Note the server's IP address.

### 2. Connect and Run Setup

SSH into your new server:

```bash
ssh root@YOUR_SERVER_IP
```

Run the setup script:

```bash
curl -fsSL https://raw.githubusercontent.com/andrewhawkins13/roamdev/master/setup.sh | bash
```

Or run commands manually:

<details>
<summary>Manual setup steps</summary>

```bash
# Create non-root user
useradd -m -s /bin/bash dev
usermod -aG sudo dev
echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
mkdir -p /home/dev/.ssh
cp /root/.ssh/authorized_keys /home/dev/.ssh/
chown -R dev:dev /home/dev/.ssh
chmod 700 /home/dev/.ssh
chmod 600 /home/dev/.ssh/authorized_keys

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

# Install tools (as dev user)
su - dev << 'EOF'
# Node.js via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# Claude Code
npm install -g @anthropic-ai/claude-code

# Create projects directory
mkdir -p ~/projects
EOF

# Install Nginx
apt-get install -y nginx tmux
mkdir -p /var/www/dev
chown dev:dev /var/www/dev

cat > /etc/nginx/sites-available/dev << 'NGINX'
server {
    listen 80 default_server;
    root /var/www/dev;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/dev /etc/nginx/sites-enabled/dev
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
```

</details>

### 3. Authenticate Tailscale

When you run `tailscale up`, you'll get a URL. Open it to connect the server to your Tailscale network.

Get your Tailscale IP:

```bash
tailscale ip -4
```

### 4. Set Up Your Phone

1. Install **Tailscale** app, log in with the same account
2. Install **Termius** (or your preferred SSH client)
3. In Termius, create a new host:
   - **Host:** Your Tailscale IP (100.x.x.x)
   - **Username:** dev
   - **Key:** Import your SSH private key

## Usage

### Start Coding

```bash
# Connect via SSH
ssh dev@YOUR_TAILSCALE_IP

# Start a persistent session
tmux new -s dev

# Create a project
cd ~/projects
mkdir my-app && cd my-app

# Run Claude Code
claude
```

### Preview Your Work

Open in your phone's browser:
- **Private:** `http://YOUR_TAILSCALE_IP` (requires Tailscale)
- **Public:** `http://YOUR_SERVER_IP`

### Reconnect Later

```bash
tmux attach -t dev
```

## Tips

- **tmux keeps sessions alive** — disconnect anytime, reconnect later
- **Use Tailscale IP** for private access (more secure)
- **Ask Claude to set up SSL** when you're ready to go public
- **Ask Claude to connect a domain** when you need one

## Costs

| Service | Cost |
|---------|------|
| Hetzner CPX11 | ~$5/mo |
| Tailscale | Free |
| Termius | Free (or $10/mo for premium) |

## License

MIT
