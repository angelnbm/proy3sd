# 🚀 Contenedores LXC Necesarios para Dashboard (App 3)

## 📊 Infraestructura Actual (Apps 1 y 2)

```
✅ 112 - App1-Principal
✅ 113 - MariaDB-Master
✅ 114 - MariaDB-Slave
✅ 115 - App1-Replica
✅ 116 - Orchestrator-DB1
✅ 400 - nginx/Gateway (Kong)
✅ 601 - App2-Principal
✅ 602 - App2-Replica
✅ 603 - Postgres-Master
✅ 604 - Postgres-Slave
✅ 605 - Patron-Etcd
```

---

## 🆕 Contenedores a Crear para App 3 (Dashboard)

### Opción 1: Infraestructura Completa (Recomendada)

| LXC | Nombre | SO | CPU | RAM | Disco | Propósito |
|-----|--------|-----|-----|-----|-------|-----------|
| **301** | `Dashboard-Principal` | Ubuntu 22.04 | 2 | 4GB | 20GB | Backend Node.js + Frontend Vue.js |
| **302** | `MySQL-Master` | Ubuntu 22.04 | 2 | 4GB | 30GB | Base de datos (escrituras) |
| **303** | `MySQL-Slave` | Ubuntu 22.04 | 2 | 4GB | 30GB | Base de datos (lecturas) |
| **304** | `Dashboard-Replica` | Ubuntu 22.04 | 2 | 4GB | 20GB | Dashboard backup (opcional pero recomendado) |
| **501** | `Kafka-Broker-1` | Ubuntu 22.04 | 2 | 6GB | 30GB | Message broker principal |
| **502** | `Kafka-Broker-2` | Ubuntu 22.04 | 2 | 6GB | 30GB | Message broker secundario |
| **500** | `Zookeeper` | Ubuntu 22.04 | 1 | 2GB | 10GB | Coordinación Kafka cluster |

**Total: 7 contenedores nuevos**

### Opción 2: Infraestructura Mínima (Para Testing)

| LXC | Nombre | SO | CPU | RAM | Disco | Propósito |
|-----|--------|-----|-----|-----|-------|-----------|
| **301** | `Dashboard-Principal` | Ubuntu 22.04 | 2 | 4GB | 20GB | Backend + Frontend |
| **302** | `MySQL-Master` | Ubuntu 22.04 | 2 | 4GB | 30GB | Base de datos única |
| **501** | `Kafka-Broker` | Ubuntu 22.04 | 2 | 6GB | 30GB | Message broker único |
| **500** | `Zookeeper` | Ubuntu 22.04 | 1 | 2GB | 10GB | Coordinación Kafka |

**Total: 4 contenedores nuevos**

---

## 🔗 Arquitectura de Conexiones

```
┌─────────────────────────────────────────────────────────────┐
│                    PROXMOX HOST                              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  APP 1 (Verificación de Eliminaciones)              │  │
│  │  LXC 112, 115 → Kafka (501, 502)                    │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │ Publica eventos                         │
│                   ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  KAFKA CLUSTER                                       │  │
│  │  LXC 500: Zookeeper                                  │  │
│  │  LXC 501: Kafka Broker 1                             │  │
│  │  LXC 502: Kafka Broker 2                             │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │ Eventos de eliminación                  │
│                   ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  APP 3 (DASHBOARD) ⭐ NUEVO                          │  │
│  │  LXC 301: Dashboard Principal                        │  │
│  │  LXC 304: Dashboard Replica (opcional)               │  │
│  │  │                                                    │  │
│  │  └──► LXC 302: MySQL Master (escrituras)             │  │
│  │       LXC 303: MySQL Slave (lecturas)                │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │ Orquestación de contratos               │
│                   ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  KONG GATEWAY                                        │  │
│  │  LXC 400: nginx/Gateway ✅ (Ya existe)               │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │ Proxy requests                          │
│                   ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  APP 2 (Gestión de Contratos)                        │  │
│  │  LXC 601, 602 → Postgres (603, 604)                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Instrucciones de Creación en Proxmox

### 1. Crear Contenedor Dashboard Principal (LXC 301)

```bash
# En Proxmox Host
pct create 301 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname dashboard-principal \
  --cores 2 \
  --memory 4096 \
  --swap 2048 \
  --rootfs local-lvm:20 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1 \
  --features nesting=1

# Iniciar contenedor
pct start 301

# Entrar al contenedor
pct enter 301

# Instalar Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs git build-essential

# Verificar instalación
node --version  # Debe mostrar v20.x
npm --version
```

### 2. Crear MySQL Master (LXC 302)

```bash
pct create 302 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname mysql-master \
  --cores 2 \
  --memory 4096 \
  --swap 2048 \
  --rootfs local-lvm:30 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1

pct start 302
pct enter 302

# Instalar MySQL 8.0
apt update && apt install -y mysql-server

# Configurar para replicación master
mysql -u root -p <<EOF
CREATE DATABASE continental_db;
CREATE USER 'continental_user'@'%' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON continental_db.* TO 'continental_user'@'%';
CREATE USER 'replicator'@'%' IDENTIFIED BY 'replication_password';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
EOF

# Editar /etc/mysql/mysql.conf.d/mysqld.cnf
# Agregar:
# server-id = 1
# log_bin = /var/log/mysql/mysql-bin.log
# bind-address = 0.0.0.0
```

### 3. Crear MySQL Slave (LXC 303)

```bash
pct create 303 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname mysql-slave \
  --cores 2 \
  --memory 4096 \
  --swap 2048 \
  --rootfs local-lvm:30 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1

pct start 303
pct enter 303

# Instalar MySQL 8.0
apt update && apt install -y mysql-server

# Configurar para replicación slave
# Editar /etc/mysql/mysql.conf.d/mysqld.cnf
# Agregar:
# server-id = 2
# relay-log = /var/log/mysql/mysql-relay-bin.log
# bind-address = 0.0.0.0
# read_only = 1
```

### 4. Crear Zookeeper (LXC 500)

```bash
pct create 500 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname zookeeper \
  --cores 1 \
  --memory 2048 \
  --swap 1024 \
  --rootfs local-lvm:10 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1

pct start 500
pct enter 500

# Instalar Java
apt update && apt install -y openjdk-11-jdk wget

# Descargar e instalar Zookeeper
cd /opt
wget https://downloads.apache.org/zookeeper/zookeeper-3.8.5/apache-zookeeper-3.8.5-bin.tar.gz
tar -xzf apache-zookeeper-3.8.3-bin.tar.gz
mv apache-zookeeper-3.8.3-bin zookeeper

# Crear configuración
mkdir -p /var/lib/zookeeper
cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg

# Editar /opt/zookeeper/conf/zoo.cfg
# dataDir=/var/lib/zookeeper
# clientPort=2181
```

### 5. Crear Kafka Broker 1 (LXC 501)

```bash
pct create 501 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname kafka-broker-1 \
  --cores 2 \
  --memory 6144 \
  --swap 2048 \
  --rootfs local-lvm:30 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1

pct start 501
pct enter 501

# Instalar Java
apt update && apt install -y openjdk-11-jdk wget

# Descargar e instalar Kafka
cd /opt
wget https://downloads.apache.org/kafka/3.7.2/kafka_2.12-3.7.2.tgz
tar -xzf kafka_2.12-3.7.2.tgz
mv kafka_2.12-3.7.2 kafka

# Configurar Kafka
# Editar /opt/kafka/config/server.properties
# broker.id=1
# listeners=PLAINTEXT://0.0.0.0:9092
# advertised.listeners=PLAINTEXT://<IP_LXC_501>:9092
# zookeeper.connect=<IP_LXC_500>:2181
# log.dirs=/var/lib/kafka-logs
```

### 6. Crear Kafka Broker 2 (LXC 502)

```bash
pct create 502 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname kafka-broker-2 \
  --cores 2 \
  --memory 6144 \
  --swap 2048 \
  --rootfs local-lvm:30 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1

pct start 502
# (Misma configuración que 501, pero con broker.id=2)
```

### 7. Crear Dashboard Replica (LXC 304) - Opcional

```bash
pct create 304 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname dashboard-replica \
  --cores 2 \
  --memory 4096 \
  --swap 2048 \
  --rootfs local-lvm:20 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1

# Misma configuración que LXC 301
```

---

## 🔧 Configuración Post-Instalación

### Obtener IPs de los Contenedores

```bash
# En Proxmox Host
pct exec 301 -- ip addr show eth0 | grep inet
pct exec 302 -- ip addr show eth0 | grep inet
pct exec 303 -- ip addr show eth0 | grep inet
pct exec 500 -- ip addr show eth0 | grep inet
pct exec 501 -- ip addr show eth0 | grep inet
pct exec 502 -- ip addr show eth0 | grep inet
```

### Desplegar Código del Dashboard en LXC 301

**Ver [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) para guía completa.**

#### Opción 1: Script Automatizado (Recomendado)

```bash
# 1. Copiar script al LXC 301
pct push 301 scripts/deploy-dashboard.sh /tmp/deploy-dashboard.sh

# 2. Entrar al LXC
pct enter 301

# 3. Ejecutar script
chmod +x /tmp/deploy-dashboard.sh
/tmp/deploy-dashboard.sh
```

#### Opción 2: Manual desde Git

```bash
# Entrar al LXC 301
pct enter 301

# Clonar repositorio
cd /opt
git clone https://github.com/tu-usuario/continental-dashboard.git
cd continental-dashboard

# Instalar dependencias
npm install --production
cd frontend && npm install && npm run build && cd ..

# Configurar .env
cp .env.production .env
nano .env  # Editar con IPs reales

# Iniciar con PM2
npm install -g pm2
pm2 start src/index.js --name continental-dashboard
pm2 save
pm2 startup
```

### Actualizar .env del Dashboard

Una vez obtengas las IPs, actualiza el archivo `.env` en LXC 301:

```bash
# Ejemplo con IPs hipotéticas
KAFKA_BROKERS=192.168.1.51:9092,192.168.1.52:9092
DB_MASTER_HOST=192.168.1.32
DB_SLAVE_HOST=192.168.1.33
KONG_GATEWAY_URL=http://192.168.1.40:8000  # Tu LXC 400 existente
```

---

## 🔐 Firewall y Seguridad

### Dashboard (LXC 301)

```bash
ufw allow 3000/tcp  # API Backend
ufw allow 8080/tcp  # Frontend
ufw enable
```

### MySQL Master/Slave (LXC 302, 303)

```bash
# Solo permitir desde Dashboard
ufw allow from <IP_LXC_301> to any port 3306 proto tcp
ufw enable
```

### Kafka (LXC 501, 502)

```bash
# Permitir desde Dashboard y App 1
ufw allow from <IP_LXC_301> to any port 9092 proto tcp
ufw allow from <IP_LXC_112> to any port 9092 proto tcp
ufw allow from <IP_LXC_115> to any port 9092 proto tcp
# Entre brokers
ufw allow from <IP_LXC_501> to any port 9092 proto tcp
ufw allow from <IP_LXC_502> to any port 9092 proto tcp
ufw enable
```

### Zookeeper (LXC 500)

```bash
# Solo permitir desde brokers Kafka
ufw allow from <IP_LXC_501> to any port 2181 proto tcp
ufw allow from <IP_LXC_502> to any port 2181 proto tcp
ufw enable
```

---

## 📊 Resumen de Recursos

### Total de Recursos Necesarios

| Recurso | Opción Completa | Opción Mínima |
|---------|----------------|---------------|
| **Contenedores LXC** | 7 | 4 |
| **CPU Cores** | 13 | 7 |
| **RAM** | 32 GB | 16 GB |
| **Disco** | 170 GB | 90 GB |

---

## ✅ Checklist de Creación

- [ ] LXC 500 - Zookeeper
- [ ] LXC 501 - Kafka Broker 1
- [ ] LXC 502 - Kafka Broker 2
- [ ] LXC 302 - MySQL Master
- [ ] LXC 303 - MySQL Slave
- [ ] LXC 301 - Dashboard Principal
- [ ] LXC 304 - Dashboard Replica (opcional)
- [ ] Configurar replicación MySQL
- [ ] Configurar cluster Kafka
- [ ] Obtener y documentar IPs
- [ ] Actualizar `.env` en Dashboard
- [ ] Configurar firewall en todos los LXC
- [ ] Test de conectividad entre servicios
- [ ] Desplegar código del Dashboard

---

## 🚀 Orden de Creación Recomendado

1. **LXC 500** (Zookeeper) - Primero, otros dependen de él
2. **LXC 501, 502** (Kafka) - Segundo, App 1 necesita publicar eventos
3. **LXC 302, 303** (MySQL) - Tercero, configurar replicación
4. **LXC 301** (Dashboard) - Cuarto, consumir de Kafka y escribir a MySQL
5. **LXC 304** (Replica) - Último, opcional para HA

---

## 🔗 Integración con Apps Existentes

### Modificar App 1 (LXC 112, 115)

Actualizar configuración de Kafka para publicar eventos:

```bash
# En App 1
KAFKA_BROKERS=<IP_LXC_501>:9092,<IP_LXC_502>:9092
KAFKA_TOPIC=continental.events
```

### Kong Gateway (LXC 400) ✅

Ya existe, asegúrate de que tenga:
- Ruta a App 2 configurada
- Accesible desde Dashboard (LXC 301)

---

## 📞 Testing Post-Despliegue

```bash
# Desde Dashboard (LXC 301)
./scripts/test-connectivity.sh

# Test manual de cada servicio
telnet <IP_KAFKA_501> 9092
mysql -h <IP_MYSQL_302> -u continental_user -p
curl http://<IP_KONG_400>:8000/
```

---

## 🎯 Resultado Final

Una vez completada la instalación tendrás:

```
✅ 112 - App1-Principal
✅ 113 - MariaDB-Master (App1)
✅ 114 - MariaDB-Slave (App1)
✅ 115 - App1-Replica
✅ 116 - Orchestrator-DB1
⭐ 301 - Dashboard-Principal (NUEVO)
⭐ 302 - MySQL-Master (NUEVO)
⭐ 303 - MySQL-Slave (NUEVO)
⭐ 304 - Dashboard-Replica (NUEVO - Opcional)
✅ 400 - nginx/Gateway (Kong)
⭐ 500 - Zookeeper (NUEVO)
⭐ 501 - Kafka-Broker-1 (NUEVO)
⭐ 502 - Kafka-Broker-2 (NUEVO)
✅ 601 - App2-Principal
✅ 602 - App2-Replica
✅ 603 - Postgres-Master (App2)
✅ 604 - Postgres-Slave (App2)
✅ 605 - Patron-Etcd
```

**Total: 18-19 contenedores LXC** formando un sistema distribuido completo. 🚀
