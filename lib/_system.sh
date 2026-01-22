#!/bin/bash
# ==========================================================
# System functions for Whaticket installer
# Execution model:
# - devconnectai runs as normal user with sudo
# - this file NEVER uses su or root shells
# ==========================================================

set -euo pipefail

DEPLOY_USER="deployautomatizaai"
DEPLOY_HOME="/home/${DEPLOY_USER}"

# ----------------------------------------------------------
# SYSTEM UPDATE
# ----------------------------------------------------------
system_update() {
  sudo apt update -y
  sudo apt upgrade -y
}

# ----------------------------------------------------------
# TIMEZONE
# ----------------------------------------------------------
system_set_timezone() {
  sudo timedatectl set-timezone America/Sao_Paulo
}

# ----------------------------------------------------------
# UFW
# ----------------------------------------------------------
system_set_ufw() {
  sudo apt install -y ufw

  sudo ufw allow 22
  sudo ufw allow 80
  sudo ufw allow 443
  sudo ufw allow 3000
  sudo ufw allow 3003
  sudo ufw allow 6379
  sudo ufw allow 5432

  sudo ufw --force enable
}

# ----------------------------------------------------------
# NODE + POSTGRES
# ----------------------------------------------------------
system_node_install() {
  # Node.js 20
  if ! command -v node >/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
  fi

  sudo npm install -g npm@latest

  # PostgreSQL 15
  if ! command -v psql >/dev/null; then
    sudo apt install -y curl ca-certificates gnupg lsb-release

    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | sudo gpg --dearmor -o /usr/share/keyrings/postgres.gpg

    echo \
      "deb [signed-by=/usr/share/keyrings/postgres.gpg] \
      http://apt.postgresql.org/pub/repos/apt \
      $(lsb_release -cs)-pgdg main" \
      | sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null

    sudo apt update
    sudo apt install -y postgresql-15 postgresql-contrib
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
  fi
}

# ----------------------------------------------------------
# PM2
# ----------------------------------------------------------
system_pm2_install() {
  sudo npm install -g pm2

  sudo -u "$DEPLOY_USER" pm2 startup systemd \
    -u "$DEPLOY_USER" \
    --hp "$DEPLOY_HOME"
}

# ----------------------------------------------------------
# DOCKER
# ----------------------------------------------------------
system_docker_install() {
  if command -v docker >/dev/null; then
    return 0
  fi

  sudo apt install -y ca-certificates curl gnupg lsb-release

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg

  echo \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io

  sudo systemctl enable docker
  sudo systemctl start docker

  sudo usermod -aG docker "$DEPLOY_USER"
}

# ----------------------------------------------------------
# PUPPETEER DEPENDENCIES
# ----------------------------------------------------------
system_puppeteer_dependencies() {
  sudo apt install -y \
    libxshmfence-dev libgbm-dev wget unzip fontconfig locales \
    gconf-service libasound2 libatk1.0-0 libc6 libcairo2 \
    libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 \
    libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 \
    libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 \
    libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 \
    libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 \
    libxrender1 libxss1 libxtst6 ca-certificates \
    fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
}

# ----------------------------------------------------------
# SNAPD
# ----------------------------------------------------------
system_snapd_install() {
  sudo apt install -y snapd
}

# ----------------------------------------------------------
# NGINX
# ----------------------------------------------------------
system_nginx_install() {
  sudo apt install -y nginx
  sudo rm -f /etc/nginx/sites-enabled/default
  sudo systemctl enable nginx
  sudo systemctl start nginx
}

system_nginx_restart() {
  sudo systemctl restart nginx
}

system_nginx_conf() {
  sudo tee /etc/nginx/conf.d/whaticket.conf >/dev/null <<'EOF'
client_max_body_size 20M;
EOF
}

# ----------------------------------------------------------
# DEPLOY USER
# ----------------------------------------------------------
system_create_user() {
  if ! id "$DEPLOY_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash -G sudo "$DEPLOY_USER"
    echo "$DEPLOY_USER:$deploy_password" | sudo chpasswd
  fi
}

system_execute_comand() {
  sudo apt install -y ffmpeg

  sudo tee /etc/sudoers.d/$DEPLOY_USER >/dev/null <<EOF
$DEPLOY_USER ALL=(ALL) NOPASSWD: ALL
EOF

  sudo chmod 440 /etc/sudoers.d/$DEPLOY_USER
}

# ----------------------------------------------------------
# UNZIP PROJECT
# ----------------------------------------------------------
system_unzip_whaticket() {
  local zip="${PROJECT_ROOT}/whaticket.zip"

  if [[ -f "$zip" ]]; then
    sudo mv "$zip" "$DEPLOY_HOME/"
    sudo chown "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_HOME/whaticket.zip"

    sudo -u "$DEPLOY_USER" unzip -o \
      "$DEPLOY_HOME/whaticket.zip" \
      -d "$DEPLOY_HOME"
  fi
}
