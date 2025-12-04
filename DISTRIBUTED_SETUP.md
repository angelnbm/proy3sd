# Configuración de Ambiente Distribuido

## Arquitectura de Red

```
┌─────────────────────────────────────────────────────────────┐
│                    RED CONTINENTAL CLUSTER                   │
│                     (192.168.1.0/24)                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   LXC 501       │  │   LXC 502       │  │   LXC 303       │
│ Kafka Broker 1  │  │ Kafka Broker 2  │  │  MySQL Slave    │
│ 192.168.1.51    │  │ 192.168.1.52    │  │  192.168.1.33   │
│   :9092         │  │   :9092         │  │   :3306         │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                     │
         │    ┌──────────────────────┐             │
         └────│   LXC 301            │─────────────┘
              │   Dashboard          │
              │   192.168.1.31       │──────┐
              │   :3000              │      │
              └──────────────────────┘      │
                        │                   │
         ┌──────────────┴──────────────┐    │
         │                             │    │
┌────────▼────────┐          ┌─────────▼────▼───┐
│   LXC 400       │          │   LXC 302        │
│  Kong Gateway   │          │  MySQL Master    │
│  192.168.1.40   │          │  192.168.1.32    │
│   :8000         │          │   :3306          │
└─────────────────┘          └──────────────────┘
         │
         │ (proxy a App 2)
         ▼
   App 2 - Contracts
```

---

## Mapeo de Servicios por IP

| Servicio | LXC | IP | Puerto | Función |
|----------|-----|-------------|--------|---------|
| **Dashboard** | 301 | 192.168.1.31 | 3000 | Backend + Frontend |
| **MySQL Master** | 302 | 192.168.1.32 | 3306 | Base de datos (Escritura) |
| **MySQL Slave** | 303 | 192.168.1.33 | 3306 | Base de datos (Lectura) |
| **Kong Gateway** | 400 | 192.168.1.40 | 8000 | API Gateway |
| **Kafka Broker 1** | 501 | 192.168.1.51 | 9092 | Message Broker |
| **Kafka Broker 2** | 502 | 192.168.1.52 | 9092 | Message Broker |

---

## Configuración por Ambiente

### 1. Desarrollo Local (Docker Compose)

```bash
cp .env.development .env
docker-compose up -d
```

Todo corre en `localhost` con puertos mapeados.

### 2. Producción (LXC Distribuido)

```bash
cp .env.production .env

# Editar .env con las IPs reales:
nano .env

# Variables críticas a modificar:
# - KAFKA_BROKERS
# - DB_MASTER_HOST
# - DB_SLAVE_HOST
# - KONG_GATEWAY_URL
# - FRONTEND_URL
```

---

## Pasos para Desplegar en Nuevo Cluster

### Opción A: IPs Diferentes (Mismo Rango)

Si cambias a otro rango de red (ej: `10.0.0.0/24`):

```bash
# 1. Copiar y editar archivo de producción
cp .env.production .env.custom

# 2. Cambiar todas las IPs
sed -i 's/192.168.1/10.0.0/g' .env.custom

# 3. Validar configuración
cat .env.custom

# 4. Usar el nuevo archivo
cp .env.custom .env
```

### Opción B: IPs Completamente Diferentes

Editar `.env` manualmente:

```bash
# Ejemplo: Kafka en la nube
KAFKA_BROKERS=kafka1.tudominio.com:9092,kafka2.tudominio.com:9092

# MySQL en servidor remoto
DB_MASTER_HOST=mysql-master.tudominio.com
DB_SLAVE_HOST=mysql-slave.tudominio.com

# Kong en DMZ
KONG_GATEWAY_URL=http://kong.tudominio.com:8000
```

---

## Verificación de Conectividad

### Script de Validación

Crea: `scripts/test-connectivity.sh`

```bash
#!/bin/bash

echo "=== Testing Continental Dashboard Connectivity ==="

# Load environment
source .env

# Test Kafka
echo -n "Kafka Brokers: "
IFS=',' read -ra BROKERS <<< "$KAFKA_BROKERS"
for broker in "${BROKERS[@]}"; do
  nc -zv ${broker%%:*} ${broker##*:} 2>&1 | grep -q succeeded && echo "✓ $broker" || echo "✗ $broker"
done

# Test MySQL Master
echo -n "MySQL Master: "
nc -zv $DB_MASTER_HOST $DB_MASTER_PORT 2>&1 | grep -q succeeded && echo "✓" || echo "✗"

# Test MySQL Slave
echo -n "MySQL Slave: "
nc -zv $DB_SLAVE_HOST $DB_SLAVE_PORT 2>&1 | grep -q succeeded && echo "✓" || echo "✗"

# Test Kong
echo -n "Kong Gateway: "
curl -s ${KONG_GATEWAY_URL}/health > /dev/null && echo "✓" || echo "✗"
```

### Ejecutar desde el Dashboard:

```bash
chmod +x scripts/test-connectivity.sh
./scripts/test-connectivity.sh
```

---

## Configuración de Frontend para IPs Dinámicas

### Actualizar `frontend/.env.production`:

```bash
# IP del backend (Dashboard)
VITE_API_BASE_URL=http://192.168.1.31:3000
VITE_SOCKET_URL=http://192.168.1.31:3000

# Para diferentes IPs, cambiar aquí
```

### Build con IP personalizada:

```bash
cd frontend
VITE_API_BASE_URL=http://10.0.0.31:3000 npm run build
```

---

## Firewall y Seguridad

### Puertos a Abrir en Cada LXC:

```bash
# LXC 301 (Dashboard)
ufw allow 3000/tcp

# LXC 302/303 (MySQL)
ufw allow from 192.168.1.31 to any port 3306 proto tcp

# LXC 400 (Kong)
ufw allow 8000/tcp

# LXC 501/502 (Kafka)
ufw allow from 192.168.1.31 to any port 9092 proto tcp
```

---

## Monitoreo de Conectividad

### Health Check Endpoint:

```bash
curl http://192.168.1.31:3000/health
```

Respuesta esperada:
```json
{
  "status": "healthy",
  "service": "Continental Dashboard",
  "timestamp": "2025-12-04T..."
}
```

### Logs de Conexión:

```bash
# En LXC 301
tail -f /opt/continental-dashboard/logs/app.log | grep -E "(Kafka|MySQL|Kong)"
```

---

## Troubleshooting

### Problema: No conecta a Kafka

```bash
# Verificar que Kafka está escuchando en la IP correcta
# En LXC 501/502:
netstat -tlnp | grep 9092

# Debe mostrar: 0.0.0.0:9092 o la IP específica
```

### Problema: MySQL Connection Refused

```bash
# Verificar bind-address en MySQL
# En LXC 302/303:
mysql -u root -p -e "SHOW VARIABLES LIKE 'bind_address';"

# Debe ser 0.0.0.0 o la IP del servidor
```

### Problema: Kong Gateway Timeout

```bash
# Verificar que Kong puede alcanzar App 2
# En LXC 400:
curl -v http://app2-host:port/health
```

---

## Configuración Avanzada: Multi-Region

Para desplegar en múltiples datacenters:

```bash
# Region 1 (Principal)
KAFKA_BROKERS=us-east-kafka1:9092,us-east-kafka2:9092
DB_MASTER_HOST=us-east-mysql-master
DB_SLAVE_HOST=us-east-mysql-slave

# Region 2 (Backup)
KAFKA_BROKERS=us-west-kafka1:9092,us-west-kafka2:9092
DB_MASTER_HOST=us-west-mysql-master
DB_SLAVE_HOST=us-west-mysql-slave
```

Usa DNS para failover automático.

---

## Resumen

✅ **El proyecto YA está diseñado para ambiente distribuido**

✅ **Solo necesitas actualizar el archivo `.env` con tus IPs**

✅ **Usa los archivos `.env.{ambiente}` como templates**

✅ **Valida conectividad con el script de test**

Para cualquier cambio de IP, solo edita las variables de entorno. **No requiere cambios en el código**.
