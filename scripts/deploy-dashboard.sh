#!/bin/bash

# ======================================================
# Script de Deployment Automático
# Continental Dashboard - LXC 301
# ======================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  Continental Dashboard"
echo "  Automated Deployment"
echo -e "==========================================${NC}"
echo ""

# Verificar que estamos en el LXC correcto
if [ ! -d "/opt" ]; then
    echo -e "${RED}Error: Directorio /opt no encontrado${NC}"
    exit 1
fi

# Variables configurables
INSTALL_DIR="/opt/continental-dashboard"
GIT_REPO=""
GIT_BRANCH="main"

# Preguntar método de instalación
echo -e "${YELLOW}¿Cómo quieres obtener el código?${NC}"
echo "1) Git Clone desde repositorio remoto"
echo "2) El código ya está en este servidor"
echo ""
read -p "Opción (1-2): " INSTALL_METHOD

case $INSTALL_METHOD in
    1)
        read -p "URL del repositorio Git: " GIT_REPO
        read -p "Rama a usar [main]: " BRANCH_INPUT
        GIT_BRANCH=${BRANCH_INPUT:-main}
        
        echo -e "${BLUE}Clonando repositorio...${NC}"
        cd /opt
        
        # Eliminar si existe
        if [ -d "$INSTALL_DIR" ]; then
            echo -e "${YELLOW}El directorio ya existe. ¿Eliminarlo? (s/n)${NC}"
            read -p "> " CONFIRM
            if [ "$CONFIRM" = "s" ]; then
                rm -rf "$INSTALL_DIR"
            else
                echo -e "${RED}Cancelado${NC}"
                exit 1
            fi
        fi
        
        git clone -b $GIT_BRANCH $GIT_REPO $INSTALL_DIR
        ;;
    2)
        if [ -d "$INSTALL_DIR" ]; then
            echo -e "${GREEN}✓ Código encontrado en $INSTALL_DIR${NC}"
        else
            echo -e "${RED}Error: No se encontró código en $INSTALL_DIR${NC}"
            echo "Por favor, copia el código a ese directorio primero."
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

# Navegar al directorio del proyecto
cd $INSTALL_DIR

# Verificar Node.js
echo -e "${BLUE}Verificando Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js no encontrado. Instalando...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs build-essential
fi

NODE_VERSION=$(node --version)
echo -e "${GREEN}✓ Node.js $NODE_VERSION${NC}"

# Instalar dependencias del backend
echo -e "${BLUE}Instalando dependencias del backend...${NC}"
npm install --production

# Instalar dependencias del frontend
echo -e "${BLUE}Instalando dependencias del frontend...${NC}"
cd frontend
npm install

# Build del frontend
echo -e "${BLUE}Compilando frontend...${NC}"
npm run build
cd ..

echo -e "${GREEN}✓ Dependencias instaladas${NC}"

# Configurar archivo .env
echo -e "${BLUE}Configurando archivo .env...${NC}"

if [ -f ".env" ]; then
    echo -e "${YELLOW}.env ya existe. ¿Sobrescribir? (s/n)${NC}"
    read -p "> " OVERWRITE
    if [ "$OVERWRITE" != "s" ]; then
        echo "Manteniendo .env existente"
    else
        cp .env.production .env
        echo -e "${YELLOW}⚠️  Archivo .env creado. DEBES editarlo con las IPs correctas.${NC}"
    fi
else
    cp .env.production .env
    echo -e "${YELLOW}⚠️  Archivo .env creado. DEBES editarlo con las IPs correctas.${NC}"
fi

# Crear directorio de logs
mkdir -p logs
chmod 755 logs

# Preguntar por configuración de IPs
echo ""
echo -e "${YELLOW}¿Quieres configurar las IPs ahora? (s/n)${NC}"
read -p "> " CONFIG_NOW

if [ "$CONFIG_NOW" = "s" ]; then
    echo ""
    echo "Ingresa las IPs de los servicios:"
    
    read -p "IP Kafka Broker 1 [192.168.1.51]: " KAFKA1
    KAFKA1=${KAFKA1:-192.168.1.51}
    
    read -p "IP Kafka Broker 2 [192.168.1.52]: " KAFKA2
    KAFKA2=${KAFKA2:-192.168.1.52}
    
    read -p "IP MySQL Master [192.168.1.32]: " MYSQL_MASTER
    MYSQL_MASTER=${MYSQL_MASTER:-192.168.1.32}
    
    read -p "IP MySQL Slave [192.168.1.33]: " MYSQL_SLAVE
    MYSQL_SLAVE=${MYSQL_SLAVE:-192.168.1.33}
    
    read -p "IP Kong Gateway [192.168.1.40]: " KONG_IP
    KONG_IP=${KONG_IP:-192.168.1.40}
    
    read -p "Usuario MySQL [continental_user]: " MYSQL_USER
    MYSQL_USER=${MYSQL_USER:-continental_user}
    
    read -sp "Password MySQL: " MYSQL_PASS
    echo ""
    
    # Actualizar .env
    sed -i "s|KAFKA_BROKERS=.*|KAFKA_BROKERS=${KAFKA1}:9092,${KAFKA2}:9092|" .env
    sed -i "s|DB_MASTER_HOST=.*|DB_MASTER_HOST=${MYSQL_MASTER}|" .env
    sed -i "s|DB_SLAVE_HOST=.*|DB_SLAVE_HOST=${MYSQL_SLAVE}|" .env
    sed -i "s|DB_MASTER_USER=.*|DB_MASTER_USER=${MYSQL_USER}|" .env
    sed -i "s|DB_SLAVE_USER=.*|DB_SLAVE_USER=${MYSQL_USER}|" .env
    sed -i "s|DB_MASTER_PASSWORD=.*|DB_MASTER_PASSWORD=${MYSQL_PASS}|" .env
    sed -i "s|DB_SLAVE_PASSWORD=.*|DB_SLAVE_PASSWORD=${MYSQL_PASS}|" .env
    sed -i "s|KONG_GATEWAY_URL=.*|KONG_GATEWAY_URL=http://${KONG_IP}:8000|" .env
    sed -i "s|CONTRACT_SERVICE_URL=.*|CONTRACT_SERVICE_URL=http://${KONG_IP}:8000/api/v1/contracts|" .env
    
    echo -e "${GREEN}✓ .env configurado${NC}"
fi

# Test de conectividad
echo ""
echo -e "${BLUE}Probando conectividad...${NC}"
if [ -f "scripts/test-connectivity.sh" ]; then
    chmod +x scripts/test-connectivity.sh
    bash scripts/test-connectivity.sh || echo -e "${YELLOW}⚠️  Algunos tests fallaron. Verifica las IPs.${NC}"
else
    echo -e "${YELLOW}Script de test no encontrado, saltando...${NC}"
fi

# Inicializar base de datos
echo ""
echo -e "${YELLOW}¿Quieres inicializar la base de datos ahora? (s/n)${NC}"
read -p "> " INIT_DB

if [ "$INIT_DB" = "s" ]; then
    if [ -f "scripts/init-db.sql" ]; then
        echo "Inicializando base de datos..."
        mysql -h ${MYSQL_MASTER} -u ${MYSQL_USER} -p${MYSQL_PASS} continental_db < scripts/init-db.sql 2>/dev/null && \
            echo -e "${GREEN}✓ Base de datos inicializada${NC}" || \
            echo -e "${YELLOW}⚠️  Error al inicializar DB. Hazlo manualmente.${NC}"
    else
        echo -e "${YELLOW}Script init-db.sql no encontrado${NC}"
    fi
fi

# Instalar PM2
echo ""
echo -e "${BLUE}Instalando PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
    echo -e "${GREEN}✓ PM2 instalado${NC}"
else
    echo -e "${GREEN}✓ PM2 ya está instalado${NC}"
fi

# Preguntar si iniciar ahora
echo ""
echo -e "${YELLOW}¿Quieres iniciar la aplicación ahora? (s/n)${NC}"
read -p "> " START_NOW

if [ "$START_NOW" = "s" ]; then
    echo -e "${BLUE}Iniciando Continental Dashboard...${NC}"
    
    # Detener si ya está corriendo
    pm2 delete continental-dashboard 2>/dev/null || true
    
    # Iniciar
    pm2 start src/index.js --name continental-dashboard
    
    # Guardar configuración
    pm2 save
    
    # Configurar inicio automático
    pm2 startup systemd -u root --hp /root
    
    echo ""
    echo -e "${GREEN}✓ Aplicación iniciada${NC}"
    echo ""
    echo "Ver logs: pm2 logs continental-dashboard"
    echo "Ver status: pm2 status"
    echo "Reiniciar: pm2 restart continental-dashboard"
    
    # Mostrar logs por 5 segundos
    sleep 2
    echo ""
    echo -e "${BLUE}Últimos logs:${NC}"
    pm2 logs continental-dashboard --lines 20 --nostream
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  ✓ Deployment Completado"
echo -e "==========================================${NC}"
echo ""
echo "Ubicación: $INSTALL_DIR"
echo "Configuración: $INSTALL_DIR/.env"
echo "Logs: $INSTALL_DIR/logs/"
echo ""

if [ "$START_NOW" != "s" ]; then
    echo "Para iniciar la aplicación:"
    echo "  cd $INSTALL_DIR"
    echo "  pm2 start src/index.js --name continental-dashboard"
    echo "  pm2 save"
fi

echo ""
echo "Verificar salud:"
echo "  curl http://localhost:3000/health"
echo ""
echo "Ver logs:"
echo "  pm2 logs continental-dashboard"
echo ""

echo -e "${BLUE}Próximos pasos:${NC}"
echo "1. Verificar que la app está corriendo: pm2 status"
echo "2. Revisar logs: pm2 logs"
echo "3. Test health endpoint: curl http://localhost:3000/health"
echo "4. Configurar firewall: ufw allow 3000/tcp && ufw allow 8080/tcp"
echo "5. Revisar DEPLOYMENT_GUIDE.md para más información"
echo ""
