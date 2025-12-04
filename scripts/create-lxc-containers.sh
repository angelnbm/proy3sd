#!/bin/bash

# ======================================================
# Script Automatizado para Crear Contenedores LXC
# Continental Dashboard (App 3)
# ======================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  Continental Dashboard - App 3"
echo "  Creación Automática de LXC"
echo -e "==========================================${NC}"
echo ""

# Verificar que estamos en el host Proxmox
if ! command -v pct &> /dev/null; then
    echo -e "${RED}Error: Este script debe ejecutarse en el host Proxmox${NC}"
    exit 1
fi

# Variables configurables
TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
STORAGE="local-lvm"
BRIDGE="vmbr0"

# Preguntar qué configuración usar
echo -e "${YELLOW}Selecciona la configuración a instalar:${NC}"
echo "1) Infraestructura Completa (7 LXC: Dashboard, MySQL M/S, Kafka x2, Zookeeper, Replica)"
echo "2) Infraestructura Mínima (4 LXC: Dashboard, MySQL, Kafka, Zookeeper)"
echo "3) Solo Kafka + Zookeeper (3 LXC: útil si ya tienes MySQL)"
echo "4) Solo Dashboard + MySQL (3 LXC: útil si usarás Kafka externo)"
echo ""
read -p "Opción (1-4): " CONFIG_OPTION

# Función para crear contenedor
create_lxc() {
    local ID=$1
    local NAME=$2
    local CORES=$3
    local MEMORY=$4
    local DISK=$5
    
    echo -e "${BLUE}Creando LXC $ID - $NAME...${NC}"
    
    if pct status $ID &> /dev/null; then
        echo -e "${YELLOW}Warning: LXC $ID ya existe. Saltando...${NC}"
        return 0
    fi
    
    pct create $ID $TEMPLATE \
        --hostname $NAME \
        --cores $CORES \
        --memory $MEMORY \
        --swap $((MEMORY / 2)) \
        --rootfs $STORAGE:$DISK \
        --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
        --unprivileged 1 \
        --features nesting=1 \
        --onboot 1
    
    echo -e "${GREEN}✓ LXC $ID creado${NC}"
    
    # Iniciar contenedor
    pct start $ID
    sleep 3
    
    # Obtener IP
    IP=$(pct exec $ID -- ip -4 addr show eth0 | grep inet | awk '{print $2}' | cut -d/ -f1)
    echo -e "${GREEN}✓ LXC $ID iniciado - IP: $IP${NC}"
    echo "$ID|$NAME|$IP" >> /tmp/lxc_ips.txt
}

# Función para instalar software base
install_base() {
    local ID=$1
    echo -e "${BLUE}Instalando software base en LXC $ID...${NC}"
    pct exec $ID -- bash -c "apt update && apt upgrade -y && apt install -y curl wget git net-tools ufw"
    echo -e "${GREEN}✓ Software base instalado en LXC $ID${NC}"
}

# Limpiar archivo de IPs
rm -f /tmp/lxc_ips.txt

# Crear contenedores según opción seleccionada
case $CONFIG_OPTION in
    1)
        echo -e "${GREEN}Instalando Infraestructura Completa...${NC}"
        create_lxc 500 "zookeeper" 1 2048 10
        create_lxc 501 "kafka-broker-1" 2 6144 30
        create_lxc 502 "kafka-broker-2" 2 6144 30
        create_lxc 302 "mysql-master" 2 4096 30
        create_lxc 303 "mysql-slave" 2 4096 30
        create_lxc 301 "dashboard-principal" 2 4096 20
        create_lxc 304 "dashboard-replica" 2 4096 20
        ;;
    2)
        echo -e "${GREEN}Instalando Infraestructura Mínima...${NC}"
        create_lxc 500 "zookeeper" 1 2048 10
        create_lxc 501 "kafka-broker-1" 2 6144 30
        create_lxc 302 "mysql-master" 2 4096 30
        create_lxc 301 "dashboard-principal" 2 4096 20
        ;;
    3)
        echo -e "${GREEN}Instalando Solo Kafka + Zookeeper...${NC}"
        create_lxc 500 "zookeeper" 1 2048 10
        create_lxc 501 "kafka-broker-1" 2 6144 30
        create_lxc 502 "kafka-broker-2" 2 6144 30
        ;;
    4)
        echo -e "${GREEN}Instalando Solo Dashboard + MySQL...${NC}"
        create_lxc 302 "mysql-master" 2 4096 30
        create_lxc 303 "mysql-slave" 2 4096 30
        create_lxc 301 "dashboard-principal" 2 4096 20
        ;;
    *)
        echo -e "${RED}Opción inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}=========================================="
echo "  Contenedores Creados Exitosamente"
echo -e "==========================================${NC}"
echo ""

# Mostrar IPs asignadas
echo -e "${YELLOW}IPs asignadas:${NC}"
echo ""
printf "%-5s %-25s %-15s\n" "LXC" "NOMBRE" "IP"
echo "------------------------------------------------"
while IFS='|' read -r id name ip; do
    printf "%-5s %-25s %-15s\n" "$id" "$name" "$ip"
done < /tmp/lxc_ips.txt

echo ""
echo -e "${BLUE}=========================================="
echo "  Próximos Pasos"
echo -e "==========================================${NC}"
echo ""
echo "1. Instalar software específico en cada LXC:"
echo "   - LXC 500: Zookeeper"
echo "   - LXC 501/502: Kafka"
echo "   - LXC 302/303: MySQL 8.0"
echo "   - LXC 301/304: Node.js 20"
echo ""
echo "2. Configurar replicación MySQL (302 -> 303)"
echo ""
echo "3. Configurar cluster Kafka (501, 502 -> 500)"
echo ""
echo "4. Actualizar .env del Dashboard con las IPs mostradas arriba"
echo ""
echo "5. Ver guía completa en: PROXMOX_LXC_SETUP.md"
echo ""

# Guardar IPs en archivo para referencia
cp /tmp/lxc_ips.txt ~/continental_lxc_ips.txt
echo -e "${GREEN}✓ IPs guardadas en ~/continental_lxc_ips.txt${NC}"
echo ""

# Ofrecer instalar software automáticamente
read -p "¿Instalar software base (curl, wget, git) en todos los LXC? (s/n): " INSTALL_BASE

if [ "$INSTALL_BASE" = "s" ] || [ "$INSTALL_BASE" = "S" ]; then
    echo ""
    while IFS='|' read -r id name ip; do
        install_base $id
    done < /tmp/lxc_ips.txt
    echo -e "${GREEN}✓ Software base instalado en todos los LXC${NC}"
fi

echo ""
echo -e "${GREEN}¡Instalación completada!${NC}"
echo ""
