#!/bin/bash
# 
# Funções para configurar o frontend do aplicativo

#######################################
# Instala pacotes do Node.js
# Argumentos:
#   Nenhum
#######################################
frontend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy npm install --prefix /home/deploy/${instancia_add}/frontend
}

#######################################
# Compila o código do frontend
# Argumentos:
#   Nenhum
#######################################
frontend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy npm run build --prefix /home/deploy/${instancia_add}/frontend
}

#######################################
# Atualiza o código do frontend
# Argumentos:
#   Nenhum
#######################################
frontend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy pm2 stop ${instancia_atualizar}-frontend
  sudo -u deploy git -C /home/deploy/${instancia_atualizar} pull
  sudo -u deploy npm install --prefix /home/deploy/${instancia_atualizar}/frontend
  sudo -u deploy rm -rf /home/deploy/${instancia_atualizar}/frontend/build
  sudo -u deploy npm run build --prefix /home/deploy/${instancia_atualizar}/frontend
  sudo -u deploy pm2 start /home/deploy/${instancia_atualizar}/frontend/server.js --name ${instancia_atualizar}-frontend
  sudo -u deploy pm2 save
}

#######################################
# Configura variáveis de ambiente para o frontend
# Argumentos:
#   Nenhum
#######################################
frontend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy cat <<EOF > /home/deploy/${instancia_add}/frontend/.env
REACT_APP_BACKEND_URL=http://localhost:${backend_port}
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
EOF

  sudo -u deploy cat <<EOF > /home/deploy/${instancia_add}/frontend/server.js
// Simple express server to run frontend production build;
const express = require("express");
const path = require("path");
const app = express();
app.use(express.static(path.join(__dirname, "build")));
app.get("/*", function (req, res) {
  res.sendFile(path.join(__dirname, "build", "index.html"));
});
app.listen(${frontend_port});
EOF
}

#######################################
# Inicia o frontend usando pm2
# Argumentos:
#   Nenhum
#######################################
frontend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo -u deploy pm2 start /home/deploy/${instancia_add}/frontend/server.js --name ${instancia_add}-frontend
  sudo -u deploy pm2 save
}

#######################################
# Configura o nginx para o frontend
# Argumentos:
#   Nenhum
#######################################
frontend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo cat <<EOF > /etc/nginx/sites-available/${instancia_add}-frontend
server {
  listen 80;
  server_name ${frontend_url};

  location / {
    proxy_pass http://localhost:${frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
EOF

  sudo ln -s /etc/nginx/sites-available/${instancia_add}-frontend /etc/nginx/sites-enabled/
  sudo systemctl restart nginx
}
