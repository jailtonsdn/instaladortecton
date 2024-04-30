#!/bin/bash
#
# Funções para configurar o backend do aplicativo
#######################################
# Cria o banco de dados REDIS usando o Docker
# Argumentos:
#   Nenhum
#######################################
backend_redis_create() {
  print_banner
  printf "${WHITE} 💻 Criando Redis & Banco Postgres...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo docker run --name redis-${instancia_add} -p ${redis_port}:6379 --restart always --detach redis redis-server --requirepass ${mysql_root_password}
  
  sudo -u postgres createdb ${instancia_add}
  sudo -u postgres psql -c "CREATE USER ${instancia_add} SUPERUSER INHERIT CREATEDB CREATEROLE PASSWORD '${mysql_root_password}'"
}

#######################################
# Configura variáveis de ambiente para o backend.
# Argumentos:
#   Nenhum
#######################################
backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy cat <<EOF > /home/deploy/${instancia_add}/backend/.env
NODE_ENV=
BACKEND_URL=http://192.168.5.39:${backend_port}
FRONTEND_URL=http://192.168.5.39:${frontend_port}
PROXY_PORT=80
PORT=${backend_port}

DB_HOST=localhost
DB_DIALECT=postgres
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}
DB_PORT=5432

JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}

REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
REDIS_OPT_LIMITER_MAX=1
REDIS_OPT_LIMITER_DURATION=3000

USER_LIMIT=${max_user}
CONNECTIONS_LIMIT=${max_whats}
CLOSED_SEND_BY_ME=true

GERENCIANET_SANDBOX=false
GERENCIANET_CLIENT_ID=sua-id
GERENCIANET_CLIENT_SECRET=sua_chave_secreta
GERENCIANET_PIX_CERT=nome_do_certificado
GERENCIANET_PIX_KEY=chave_pix_gerencianet
EOF
}

#######################################
# Instala dependências do Node.js
# Argumentos:
#   Nenhum
#######################################
backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy npm install --prefix /home/deploy/${instancia_add}/backend
}

#######################################
# Compila o código do backend
# Argumentos:
#   Nenhum
#######################################
backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy npm run build --prefix /home/deploy/${instancia_add}/backend
}

#######################################
# Executa migrações do banco de dados
# Argumentos:
#   Nenhum
#######################################
backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Executando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy npx sequelize db:migrate --prefix /home/deploy/${instancia_add}/backend
}

#######################################
# Executa seeds do banco de dados
# Argumentos:
#   Nenhum
#######################################
backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Executando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy npx sequelize db:seed:all --prefix /home/deploy/${instancia_add}/backend
}

#######################################
# Inicia o backend usando pm2 no modo de produção.
# Argumentos:
#   Nenhum
#######################################
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy pm2 start /home/deploy/${instancia_add}/backend/dist/server.js --name ${instancia_add}-backend
}

#######################################
# Configuração do Nginx para o backend
# Argumentos:
#   Nenhum
#######################################
backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo cat <<EOF > /etc/nginx/sites-available/${instancia_add}-backend
server {
  listen 80;
  server_name ${backend_url};

  location / {
    proxy_pass http://192.168.5.39:${backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_cache_bypass \$http_upgrade;
  }
}
EOF

  sudo ln -s /etc/nginx/sites-available/${instancia_add}-backend /etc/nginx/sites-enabled/
  sudo systemctl restart nginx
}

