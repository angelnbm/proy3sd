#!/bin/bash

# ======================================================
# Script de Instalación de Software en LXC
# Continental Dashboard - App 3
# ======================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "  Instalación de Software por LXC"
echo -e "==========================================${NC}"
echo ""

# Función para instalar Node.js 20 en Dashboard
install_nodejs() {
    local ID=$1
    echo -e "${BLUE}Instalando Node.js 20 en LXC $ID...${NC}"
    
    pct exec $ID -- bash -c "
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs build-essential
        node --version
        npm --version
    "
    
    echo -e "${GREEN}✓ Node.js 20 instalado en LXC $ID${NC}"
}

# Función para instalar MySQL 8.0
install_mysql() {
    local ID=$1
    local ROLE=$2  # master o slave
    
    echo -e "${BLUE}Instalando MySQL 8.0 en LXC $ID (${ROLE})...${NC}"
    
    pct exec $ID -- bash -c "
        apt update
        DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
        systemctl enable mysql
        systemctl start mysql
    "
    
    if [ "$ROLE" = "master" ]; then
        echo -e "${YELLOW}Configurando MySQL como Master...${NC}"
        pct exec $ID -- bash -c "
            cat > /etc/mysql/mysql.conf.d/continental.cnf <<EOF
[mysqld]
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = continental_db
bind-address = 0.0.0.0
EOF
            systemctl restart mysql
        "
    else
        echo -e "${YELLOW}Configurando MySQL como Slave...${NC}"
        pct exec $ID -- bash -c "
            cat > /etc/mysql/mysql.conf.d/continental.cnf <<EOF
[mysqld]
server-id = 2
relay-log = /var/log/mysql/mysql-relay-bin.log
bind-address = 0.0.0.0
read_only = 1
EOF
            systemctl restart mysql
        "
    fi
    
    echo -e "${GREEN}✓ MySQL 8.0 instalado en LXC $ID${NC}"
}

# Función para instalar Zookeeper
install_zookeeper() {
    local ID=$1
    echo -e "${BLUE}Instalando Zookeeper en LXC $ID...${NC}"
    
    pct exec $ID -- bash -c "
        apt update
        apt-get install -y openjdk-11-jdk wget
        
        cd /opt
        wget -q https://downloads.apache.org/zookeeper/zookeeper-3.8.3/apache-zookeeper-3.8.3-bin.tar.gz
        tar -xzf apache-zookeeper-3.8.3-bin.tar.gz
        mv apache-zookeeper-3.8.3-bin zookeeper
        rm apache-zookeeper-3.8.3-bin.tar.gz
        
        mkdir -p /var/lib/zookeeper
        
        cat > /opt/zookeeper/conf/zoo.cfg <<EOF
tickTime=2000
dataDir=/var/lib/zookeeper
clientPort=2181
maxClientCnxns=60
EOF
        
        cat > /etc/systemd/system/zookeeper.service <<EOF
[Unit]
Description=Apache Zookeeper
After=network.target

[Service]
Type=forking
User=root
ExecStart=/opt/zookeeper/bin/zkServer.sh start
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable zookeeper
        systemctl start zookeeper
    "
    
    echo -e "${GREEN}✓ Zookeeper instalado en LXC $ID${NC}"
}

# Función para instalar Kafka
install_kafka() {
    local ID=$1
    local BROKER_ID=$2
    local ZK_IP=$3
    
    echo -e "${BLUE}Instalando Kafka en LXC $ID (Broker $BROKER_ID)...${NC}"
    
    # Obtener IP del broker
    BROKER_IP=$(pct exec $ID -- ip -4 addr show eth0 | grep inet | awk '{print $2}' | cut -d/ -f1)
    
    pct exec $ID -- bash -c "
        apt update
        apt-get install -y openjdk-11-jdk wget
        
        cd /opt
        wget -q https://downloads.apache.org/kafka/3.6.0/kafka_2.13-3.6.0.tgz
        tar -xzf kafka_2.13-3.6.0.tgz
        mv kafka_2.13-3.6.0 kafka
        rm kafka_2.13-3.6.0.tgz
        
        mkdir -p /var/lib/kafka-logs
        
        cat > /opt/kafka/config/server.properties <<EOF
broker.id=$BROKER_ID
listeners=PLAINTEXT://0.0.0.0:9092
advertised.listeners=PLAINTEXT://$BROKER_IP:9092
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/var/lib/kafka-logs
num.partitions=3
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=$ZK_IP:2181
zookeeper.connection.timeout.ms=18000
group.initial.rebalance.delay.ms=0
auto.create.topics.enable=true
EOF
        
        cat > /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka
After=network.target zookeeper.service

[Service]
Type=simple
User=root
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable kafka
        systemctl start kafka
    "
    
    echo -e "${GREEN}✓ Kafka instalado en LXC $ID${NC}"
}

# Menú de instalación
echo "Selecciona qué instalar:"
echo "1) Todo (Zookeeper, Kafka, MySQL, Node.js)"
echo "2) Solo Zookeeper + Kafka"
echo "3) Solo MySQL Master + Slave"
echo "4) Solo Dashboard (Node.js)"
echo "5) Individual (seleccionar cada LXC)"
echo ""
read -p "Opción (1-5): " INSTALL_OPTION

case $INSTALL_OPTION in
    1)
        # Leer IPs del archivo
        if [ ! -f ~/continental_lxc_ips.txt ]; then
            echo -e "${RED}Error: Archivo de IPs no encontrado${NC}"
            echo "Ejecuta primero: ./create-lxc-containers.sh"
            exit 1
        fi
        
        # Obtener IP de Zookeeper
        ZK_IP=$(grep "500|" ~/continental_lxc_ips.txt | cut -d'|' -f3)
        
        echo -e "${GREEN}Instalando todo el stack...${NC}"
        install_zookeeper 500
        sleep 5
        install_kafka 501 1 $ZK_IP
        if grep -q "502|" ~/continental_lxc_ips.txt; then
            install_kafka 502 2 $ZK_IP
        fi
        install_mysql 302 master
        if grep -q "303|" ~/continental_lxc_ips.txt; then
            install_mysql 303 slave
        fi
        install_nodejs 301
        if grep -q "304|" ~/continental_lxc_ips.txt; then
            install_nodejs 304
        fi
        ;;
    2)
        ZK_IP=$(grep "500|" ~/continental_lxc_ips.txt | cut -d'|' -f3)
        install_zookeeper 500
        sleep 5
        install_kafka 501 1 $ZK_IP
        if grep -q "502|" ~/continental_lxc_ips.txt; then
            install_kafka 502 2 $ZK_IP
        fi
        ;;
    3)
        install_mysql 302 master
        if grep -q "303|" ~/continental_lxc_ips.txt; then
            install_mysql 303 slave
        fi
        ;;
    4)
        install_nodejs 301
        if grep -q "304|" ~/continental_lxc_ips.txt; then
            install_nodejs 304
        fi
        ;;
    5)
        read -p "ID del LXC: " LXC_ID
        echo "Tipo de instalación:"
        echo "1) Node.js 20"
        echo "2) MySQL Master"
        echo "3) MySQL Slave"
        echo "4) Zookeeper"
        echo "5) Kafka"
        read -p "Opción: " TYPE
        
        case $TYPE in
            1) install_nodejs $LXC_ID ;;
            2) install_mysql $LXC_ID master ;;
            3) install_mysql $LXC_ID slave ;;
            4) install_zookeeper $LXC_ID ;;
            5)
                read -p "ID del broker (1 o 2): " BID
                read -p "IP de Zookeeper: " ZK_IP
                install_kafka $LXC_ID $BID $ZK_IP
                ;;
        esac
        ;;
esac

echo ""
echo -e "${GREEN}¡Instalación completada!${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "1. Configurar replicación MySQL (si aplica)"
echo "2. Crear base de datos y usuario en MySQL"
echo "3. Crear topic en Kafka"
echo "4. Desplegar código del Dashboard"
echo ""
