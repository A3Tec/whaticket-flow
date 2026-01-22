#!/bin/bash

#######################################
# Configurações e Constantes
#######################################
readonly POSTGRES_VERSION="15"
readonly NODE_VERSION="20"
readonly TIMEZONE="America/Sao_Paulo"

#######################################
# Cria usuário do sistema
# Globals:
#   deploy_password
#   PROJECT_ROOT
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Criando usuário deployautomatizaai...${GRAY_LIGHT}\n\n"
  sleep 2
 
  # Validação de senha
  if [[ -z "$deploy_password" ]]; then
    printf "${RED} ❌ Senha não definida!${NC}\n"
    return 1
  fi

  local encrypted_password
  encrypted_password=$(openssl passwd -6 "$deploy_password")
  
  sudo useradd -m -p "$encrypted_password" -s /bin/bash -G sudo deployautomatizaai || {
    printf "${RED} ❌ Erro ao criar usuário!${NC}\n"
    return 1
  }
  
  # Move arquivo se existir
  if [[ -f "${PROJECT_ROOT}/whaticket.zip" ]]; then
    sudo mv "${PROJECT_ROOT}/whaticket.zip" /home/deployautomatizaai/
    sudo chown deployautomatizaai:deployautomatizaai /home/deployautomatizaai/whaticket.zip
  fi

  sleep 2
}

#######################################
# Descompacta whaticket
# Arguments:
#   None
#######################################
system_unzip_whaticket() {
  print_banner
  printf "${WHITE} 💻 Descompactando whaticket...${GRAY_LIGHT}\n\n"
  sleep 2

  if [[ ! -f /home/deployautomatizaai/whaticket.zip ]]; then
    printf "${RED} ❌ Arquivo whaticket.zip não encontrado!${NC}\n"
    return 1
  fi

  sudo -u deployautomatizaai bash -c 'cd ~ && unzip -q whaticket.zip' || {
    printf "${RED} ❌ Erro ao descompactar!${NC}\n"
    return 1
  }

  sleep 2
}

#######################################
# Atualiza sistema e instala dependências
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando sistema...${GRAY_LIGHT}\n\n"
  sleep 2

  sudo apt-get update -y || return 1
  
  local packages=(
    libxshmfence-dev libgbm-dev wget unzip fontconfig locales
    gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2
    libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4
    libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0
    libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1
    libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6
    libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates
    fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
    ffmpeg
  )
  
  sudo apt-get install -y "${packages[@]}" || {
    printf "${RED} ❌ Erro ao instalar pacotes!${NC}\n"
    return 1
  }

  sleep 2
}

#######################################
# Instala Node.js e PostgreSQL
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Node.js ${NODE_VERSION}...${GRAY_LIGHT}\n\n"
  sleep 2

  # Instala Node.js
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo -E bash - || return 1
  sudo apt-get install -y nodejs || return 1
  sudo npm install -g npm@latest || return 1

  printf "${WHITE} 💻 Instalando PostgreSQL ${POSTGRES_VERSION}...${GRAY_LIGHT}\n\n"
  
  # Adiciona repositório PostgreSQL
  sudo sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update -y
  sudo apt-get install -y "postgresql-${POSTGRES_VERSION}" "postgresql-contrib-${POSTGRES_VERSION}" || return 1

  # Inicia PostgreSQL
  sudo systemctl start postgresql
  sudo systemctl enable postgresql

  # Configura timezone
  sudo timedatectl set-timezone "$TIMEZONE"

  sleep 2
}

#######################################
# Configura PostgreSQL
# Globals:
#   db_pass (deve ser definido externamente)
# Arguments:
#   None
#######################################
system_postgres_config() {
  print_banner
  printf "${WHITE} 💻 Configurando PostgreSQL...${GRAY_LIGHT}\n\n"
  sleep 2

  if [[ -z "$db_pass" ]]; then
    printf "${RED} ❌ Senha do banco não definida!${NC}\n"
    return 1
  fi

  # Altera senha do postgres
  sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$db_pass';" || return 1
  
  # Cria banco de dados
  sudo -u postgres psql -c "CREATE DATABASE whaticketautomatizaai;" || {
    printf "${YELLOW} ⚠️  Banco já existe ou erro ao criar${NC}\n"
  }

  # Instala extensões
  sudo -u postgres psql -d whaticketautomatizaai -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
  sudo -u postgres psql -d whaticketautomatizaai -c "CREATE EXTENSION IF NOT EXISTS uuid-ossp;"

  # Otimizações de performance
  sudo -u postgres psql <<EOF
    ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
    ALTER SYSTEM SET max_connections = 200;
    ALTER SYSTEM SET shared_buffers = '256MB';
    ALTER SYSTEM SET effective_cache_size = '1GB';
    ALTER SYSTEM SET maintenance_work_mem = '64MB';
    ALTER SYSTEM SET checkpoint_completion_target = 0.9;
    ALTER SYSTEM SET wal_buffers = '16MB';
    ALTER SYSTEM SET default_statistics_target = 100;
EOF

  sudo systemctl restart postgresql
  sleep 2
}

#######################################
# Instala Docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Docker...${GRAY_LIGHT}\n\n"
  sleep 2

  if ! [[ -f /etc/os-release ]]; then
    printf "${RED} ❌ Não foi possível determinar o SO${NC}\n"
    return 1
  fi

  source /etc/os-release

  case "$ID" in
    ubuntu)
      ubuntu_docker_install
      ;;
    debian)
      debian_docker_install
      ;;
    *)
      printf "${RED} ❌ SO não suportado: $ID${NC}\n"
      return 1
      ;;
  esac
}

#######################################
# Instala Docker no Ubuntu
#######################################
ubuntu_docker_install() {
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  
  # Adiciona usuário ao grupo docker
  sudo usermod -aG docker deployautomatizaai
}

#######################################
# Instala Docker no Debian
#######################################
debian_docker_install() {
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  
  sudo usermod -aG docker deployautomatizaai
}

#######################################
# Instala PM2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando PM2...${GRAY_LIGHT}\n\n"
  sleep 2

  sudo npm install -g pm2 || return 1
  
  sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u deployautomatizaai --hp /home/deployautomatizaai || {
    printf "${RED} ❌ Erro ao configurar PM2 startup${NC}\n"
    return 1
  }

  sleep 2
}

#######################################
# Configura permissões do usuário
# Arguments:
#   None
#######################################
system_execute_command() {
  print_banner
  printf "${WHITE} 💻 Configurando permissões...${GRAY_LIGHT}\n\n"
  sleep 2

  # Adiciona permissões sudo sem senha (CUIDADO: isso é um risco de segurança)
  if ! sudo grep -q "^deployautomatizaai ALL=(ALL) NOPASSWD: ALL$" /etc/sudoers; then
    echo "deployautomatizaai ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo
  fi

  sleep 2
}

#######################################
# Configura firewall UFW
# Arguments:
#   None
#######################################
system_set_ufw() {
  print_banner
  printf "${WHITE} 💻 Configurando firewall...${GRAY_LIGHT}\n\n"
  sleep 2

  local ports=(22 80 443 3000 3003 5432 6379 8080 8081 9005 9090)
  
  for port in "${ports[@]}"; do
    sudo ufw allow "$port/tcp"
  done

  sleep 2
}

#######################################
# Instala Snapd
# Arguments:
#   None
#######################################
system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Snapd...${GRAY_LIGHT}\n\n"
  sleep 2

  sudo apt-get install -y snapd || return 1
  sudo snap install core
  sudo snap refresh core

  sleep 2
}

#######################################
# Instala Certbot
# Arguments:
#   None
#######################################
system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Certbot...${GRAY_LIGHT}\n\n"
  sleep 2

  sudo apt-get remove -y certbot 2>/dev/null
  sudo snap install --classic certbot || return 1
  sudo ln -sf /snap/bin/certbot /usr/bin/certbot

  sleep 2
}

#######################################
# Instala Nginx
# Arguments:
#   None
#######################################
system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Nginx...${GRAY_LIGHT}\n\n"
  sleep 2

  sudo apt-get update
  sudo apt-get install -y nginx || return 1
  
  # Remove configuração padrão
  sudo rm -f /etc/nginx/sites-enabled/default

  sleep 2
}

#######################################
# Reinicia Nginx
# Arguments:
#   None
#######################################
system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 Reiniciando Nginx...${GRAY_LIGHT}\n\n"
  sleep 2

  sudo systemctl restart nginx || {
    printf "${RED} ❌ Erro ao reiniciar Nginx${NC}\n"
    return 1
  }

  sleep 2
}

#######################################
# Configura Nginx
# Arguments:
#   None
#######################################
system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando Nginx...${GRAY_LIGHT}\n\n"
  sleep 2

  sudo tee /etc/nginx/conf.d/whaticket.conf > /dev/null <<'EOF'
client_max_body_size 20M;
EOF

  sleep 2
}

#######################################
# Configura certificado SSL com Certbot
# Globals:
#   deploy_email
#   backend_url
#   frontend_url
# Arguments:
#   None
#######################################
system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certificado SSL...${GRAY_LIGHT}\n\n"
  sleep 2

  if [[ -z "$deploy_email" || -z "$backend_url" || -z "$frontend_url" ]]; then
    printf "${RED} ❌ Variáveis não definidas: deploy_email, backend_url ou frontend_url${NC}\n"
    return 1
  fi

  local backend_domain="${backend_url#https://}"
  local frontend_domain="${frontend_url#https://}"

  sudo certbot --nginx \
    -m "$deploy_email" \
    --agree-tos \
    --non-interactive \
    --domains "$backend_domain,$frontend_domain" || {
    printf "${RED} ❌ Erro ao configurar SSL${NC}\n"
    return 1
  }

  sleep 2
}
