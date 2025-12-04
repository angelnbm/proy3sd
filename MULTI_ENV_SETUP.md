# Continental Dashboard - Multi-Environment Deployment Guide

## Resumen

Este proyecto **ya está preparado para ambiente distribuido** con servicios en diferentes IPs. La configuración se maneja completamente mediante variables de entorno.

---

## 🎯 Quick Start

### 1. Seleccionar Ambiente

```bash
# Desarrollo local
cp .env.development .env

# Staging/Testing
cp .env.staging .env

# Producción
cp .env.production .env
```

### 2. Configurar IPs

Editar `.env` con las IPs de tu infraestructura:

```bash
# Ejemplo: Cambiar de 192.168.1.x a 10.0.0.x
KAFKA_BROKERS=10.0.0.51:9092,10.0.0.52:9092
DB_MASTER_HOST=10.0.0.32
DB_SLAVE_HOST=10.0.0.33
KONG_GATEWAY_URL=http://10.0.0.40:8000
```

### 3. Validar Conectividad

```bash
# Linux/macOS
./scripts/test-connectivity.sh

# Windows PowerShell
.\scripts\test-connectivity.ps1
```

### 4. Desplegar

```bash
# Con Docker Compose
docker-compose up -d

# O manualmente
npm install
npm start
```

---

## 📋 Ambientes Disponibles

| Archivo | Uso | Características |
|---------|-----|-----------------|
| `.env.development` | Desarrollo local | Todo en localhost, logging verbose |
| `.env.staging` | Testing pre-producción | Infraestructura de prueba |
| `.env.production` | Producción | Cluster LXC completo, logging info |
| `.env.example` | Template | Documentación de variables |

---

## 🌐 Topología de Red por Defecto

```
┌────────────────────────────────────────────────┐
│          Red Continental: 192.168.1.0/24       │
└────────────────────────────────────────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Kafka 1      │  │ Kafka 2      │  │ MySQL Slave  │
│ .51:9092     │  │ .52:9092     │  │ .33:3306     │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────┬───────┴─────────┬───────┘
                 │                 │
         ┌───────▼─────────┐       │
         │ Dashboard       │       │
         │ .31:3000        │───────┘
         └─────────┬───────┘
                   │
         ┌─────────▼─────────┬──────────────┐
         │                   │              │
   ┌─────▼─────┐      ┌──────▼──────┐      │
   │ Kong GW   │      │ MySQL Master│      │
   │ .40:8000  │      │ .32:3306    │      │
   └───────────┘      └─────────────┘      │
         │                                  │
         └──────── App 2 (Contracts) ───────┘
```

---

## 🔧 Configuración Personalizada

### Escenario 1: Cambio de Rango de Red

Si tus IPs están en `10.0.0.0/24` en lugar de `192.168.1.0/24`:

```bash
# Método rápido (Linux/macOS)
cp .env.production .env.custom
sed -i 's/192\.168\.1\./10.0.0./g' .env.custom
mv .env.custom .env

# Método rápido (Windows PowerShell)
(Get-Content .env.production) -replace '192\.168\.1\.', '10.0.0.' | Set-Content .env
```

### Escenario 2: Servicios en Diferentes Subredes

```bash
# Kafka en subnet 10.1.0.0/24
KAFKA_BROKERS=10.1.0.51:9092,10.1.0.52:9092

# MySQL en subnet 10.2.0.0/24
DB_MASTER_HOST=10.2.0.32
DB_SLAVE_HOST=10.2.0.33

# Kong en DMZ 172.16.0.0/24
KONG_GATEWAY_URL=http://172.16.0.40:8000
```

### Escenario 3: Nombres de Dominio

```bash
# Usar FQDNs en lugar de IPs
KAFKA_BROKERS=kafka1.continental.local:9092,kafka2.continental.local:9092
DB_MASTER_HOST=mysql-master.continental.local
DB_SLAVE_HOST=mysql-slave.continental.local
KONG_GATEWAY_URL=http://api-gateway.continental.local:8000
```

### Escenario 4: Servicios en la Nube

```bash
# Kafka en AWS MSK
KAFKA_BROKERS=b-1.continental.xyz.kafka.us-east-1.amazonaws.com:9092,b-2.continental.xyz.kafka.us-east-1.amazonaws.com:9092

# RDS MySQL
DB_MASTER_HOST=continental-master.abc123.us-east-1.rds.amazonaws.com
DB_SLAVE_HOST=continental-slave.abc123.us-east-1.rds.amazonaws.com

# Kong en ECS
KONG_GATEWAY_URL=http://kong-lb-123456789.us-east-1.elb.amazonaws.com:8000
```

---

## 🔍 Diagnóstico de Conectividad

### Test Automático

El script `test-connectivity` valida:
- ✅ Conectividad TCP a Kafka brokers
- ✅ Conectividad TCP a MySQL master/slave
- ✅ Respuesta HTTP de Kong Gateway
- ✅ Resolución DNS de todos los hosts

```bash
# Ejecutar validación
./scripts/test-connectivity.sh

# Output esperado:
# ✓ Kafka Broker (192.168.1.51:9092)... OK
# ✓ MySQL Master (192.168.1.32:3306)... OK
# ✓ Kong Gateway (http://192.168.1.40:8000)... OK
```

### Test Manual

```bash
# Test Kafka
telnet 192.168.1.51 9092

# Test MySQL
mysql -h 192.168.1.32 -u continental_user -p

# Test Kong
curl http://192.168.1.40:8000/
```

---

## 🔐 Seguridad y Firewall

### Reglas de Firewall Recomendadas

**Dashboard (LXC 301):**
```bash
# Permitir tráfico saliente a todos los servicios
ufw allow out to 192.168.1.32 port 3306 proto tcp  # MySQL Master
ufw allow out to 192.168.1.33 port 3306 proto tcp  # MySQL Slave
ufw allow out to 192.168.1.51 port 9092 proto tcp  # Kafka 1
ufw allow out to 192.168.1.52 port 9092 proto tcp  # Kafka 2
ufw allow out to 192.168.1.40 port 8000 proto tcp  # Kong

# Permitir acceso desde frontend
ufw allow from 192.168.1.0/24 to any port 3000 proto tcp
```

**MySQL Master/Slave:**
```bash
# Solo permitir desde Dashboard
ufw allow from 192.168.1.31 to any port 3306 proto tcp
ufw deny 3306/tcp  # Denegar resto
```

**Kafka:**
```bash
# Solo permitir desde Dashboard y otros brokers
ufw allow from 192.168.1.31 to any port 9092 proto tcp
ufw allow from 192.168.1.51 to any port 9092 proto tcp
ufw allow from 192.168.1.52 to any port 9092 proto tcp
```

---

## 📊 Monitoreo

### Health Checks

```bash
# Dashboard
curl http://192.168.1.31:3000/health

# Kong
curl http://192.168.1.40:8000/

# MySQL Master
mysql -h 192.168.1.32 -u continental_user -p -e "SELECT 1"
```

### Logs de Conectividad

```bash
# Ver logs de conexión
tail -f logs/app.log | grep -E "(Connected|Error|Retry)"

# Logs específicos de Kafka
tail -f logs/app.log | grep "Kafka"

# Logs de base de datos
tail -f logs/app.log | grep "MySQL"
```

---

## 🚀 Deployment Automático

### Script de Deployment

Crea `scripts/deploy.sh`:

```bash
#!/bin/bash

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy.sh [development|staging|production]"
  exit 1
fi

echo "Deploying to $ENVIRONMENT..."

# Copiar configuración
cp .env.$ENVIRONMENT .env

# Test conectividad
./scripts/test-connectivity.sh || exit 1

# Build
npm install --production

# Start
pm2 restart continental-dashboard || pm2 start src/index.js --name continental-dashboard

echo "✓ Deployment completed"
```

Uso:
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh production
```

---

## 🔄 Alta Disponibilidad

### Múltiples Instancias del Dashboard

Para alta disponibilidad, despliega varias instancias:

```bash
# LXC 301 (Principal)
KAFKA_BROKERS=192.168.1.51:9092,192.168.1.52:9092
KAFKA_GROUP_ID=dashboard-consumer-group

# LXC 304 (Backup)
KAFKA_BROKERS=192.168.1.51:9092,192.168.1.52:9092
KAFKA_GROUP_ID=dashboard-consumer-group  # Mismo grupo!
```

Kafka distribuirá la carga automáticamente entre ambas instancias.

### Load Balancer

Usar NGINX para balancear tráfico HTTP:

```nginx
upstream continental_dashboard {
    server 192.168.1.31:3000 weight=2;
    server 192.168.1.34:3000 weight=1 backup;
}

server {
    listen 80;
    server_name dashboard.continental.local;
    
    location / {
        proxy_pass http://continental_dashboard;
    }
}
```

---

## 📝 Checklist de Deployment

- [ ] Copiar archivo `.env` apropiado
- [ ] Actualizar IPs en `.env`
- [ ] Actualizar contraseñas en `.env`
- [ ] Ejecutar `test-connectivity`
- [ ] Verificar firewall rules
- [ ] Configurar DNS (si se usan nombres)
- [ ] Test health endpoints
- [ ] Revisar logs iniciales
- [ ] Configurar monitoreo
- [ ] Documentar configuración específica

---

## ❓ Troubleshooting

### Problema: "Cannot connect to Kafka"

```bash
# 1. Verificar que Kafka está escuchando
netstat -tlnp | grep 9092

# 2. Test desde Dashboard
telnet 192.168.1.51 9092

# 3. Revisar configuración de Kafka
# En el broker, verificar: advertised.listeners
```

### Problema: "MySQL Connection Timeout"

```bash
# 1. Verificar bind-address
mysql -u root -p -e "SHOW VARIABLES LIKE 'bind_address';"
# Debe ser: 0.0.0.0 o la IP específica

# 2. Verificar permisos
mysql -u root -p -e "SELECT host FROM mysql.user WHERE user='continental_user';"
# Debe incluir la IP del Dashboard
```

### Problema: "Kong returns 502"

```bash
# 1. Verificar que Kong puede alcanzar App 2
curl -v http://app2-host:port/health

# 2. Revisar configuración de Kong
curl http://192.168.1.40:8001/routes
```

---

## 📚 Referencias

- `ARCHITECTURE.md` - Arquitectura del sistema
- `DEPLOYMENT.md` - Guía detallada de instalación
- `API.md` - Documentación de endpoints
- `docker-compose.yml` - Configuración de contenedores

---

## ✨ Resumen

**Tu proyecto YA funciona en ambiente distribuido.** Solo necesitas:

1. ✅ Copiar el archivo `.env` apropiado
2. ✅ Actualizar las IPs
3. ✅ Ejecutar el test de conectividad
4. ✅ Deploy

**No se requieren cambios en el código.**
