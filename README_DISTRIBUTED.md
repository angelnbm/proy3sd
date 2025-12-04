# Continental Dashboard - Arquitectura Distribuida

## 📊 Resumen Ejecutivo

**Este proyecto YA ESTÁ DISEÑADO para ambiente distribuido** con componentes en diferentes IPs. No requiere modificaciones de código, solo configuración.

---

## 🏗️ Arquitectura Actual

### Componentes Distribuidos

| Componente | LXC | IP por Defecto | Puerto | Función |
|------------|-----|----------------|--------|---------|
| **Dashboard Backend** | 301 | 192.168.1.31 | 3000 | API + Kafka Consumer + WebSocket |
| **Dashboard Frontend** | 301 | 192.168.1.31 | 8080 | Vue.js UI |
| **MySQL Master** | 302 | 192.168.1.32 | 3306 | DB Escrituras |
| **MySQL Slave** | 303 | 192.168.1.33 | 3306 | DB Lecturas |
| **Kong Gateway** | 400 | 192.168.1.40 | 8000 | API Gateway |
| **Kafka Broker 1** | 501 | 192.168.1.51 | 9092 | Message Broker |
| **Kafka Broker 2** | 502 | 192.168.1.52 | 9092 | Message Broker |

### Diagrama de Conexiones

```
┌─────────────────────────────────────────────────┐
│              Cliente (Browser)                   │
└────────────┬────────────────────────────────────┘
             │ HTTP/WS
             ▼
┌────────────────────────────────────────────────┐
│  LXC 301 - Dashboard (192.168.1.31)            │
│  ┌──────────────┐      ┌──────────────┐       │
│  │  Frontend    │      │  Backend     │       │
│  │  Vue.js      │◄────►│  Express     │       │
│  │  :8080       │      │  :3000       │       │
│  └──────────────┘      └──────┬───────┘       │
└─────────────────────────────│─────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌────────────────┐
│ LXC 501/502   │    │ LXC 302       │    │ LXC 400        │
│ Kafka Cluster │    │ MySQL Master  │    │ Kong Gateway   │
│ :9092         │    │ :3306         │    │ :8000          │
└───────────────┘    └───┬───────────┘    └────────┬───────┘
                         │                         │
                         ▼                         ▼
                  ┌─────────────┐         ┌────────────────┐
                  │ LXC 303     │         │ App 2          │
                  │ MySQL Slave │         │ (Contracts)    │
                  │ :3306       │         └────────────────┘
                  └─────────────┘
```

---

## ⚙️ Configuración para Diferentes IPs

### 📝 Paso 1: Seleccionar Ambiente

```bash
# Desarrollo (todo en localhost)
cp .env.development .env

# Producción (IPs distribuidas)
cp .env.production .env

# Staging (ambiente de pruebas)
cp .env.staging .env
```

### 📝 Paso 2: Personalizar IPs

Edita el archivo `.env` con tus IPs específicas:

```bash
# Ejemplo: Cambiar de 192.168.1.x a 10.0.0.x

# Kafka
KAFKA_BROKERS=10.0.0.51:9092,10.0.0.52:9092

# MySQL
DB_MASTER_HOST=10.0.0.32
DB_SLAVE_HOST=10.0.0.33

# Kong
KONG_GATEWAY_URL=http://10.0.0.40:8000
```

### 📝 Paso 3: Configurar Frontend

```bash
cd frontend

# Producción
cp .env.production .env

# Editar con la IP del backend
VITE_API_BASE_URL=http://10.0.0.31:3000/api/v1
VITE_SOCKET_URL=http://10.0.0.31:3000
```

### 📝 Paso 4: Validar Conectividad

```bash
# Linux/macOS
./scripts/test-connectivity.sh

# Windows
.\scripts\test-connectivity.ps1
```

### 📝 Paso 5: Desplegar

```bash
# Backend
npm install
npm start

# Frontend
cd frontend
npm install
npm run build
npm run preview
```

---

## 🌐 Escenarios de Deployment

### Escenario 1: Todo en un Servidor (Desarrollo)

```bash
# .env
KAFKA_BROKERS=localhost:9092
DB_MASTER_HOST=localhost
DB_SLAVE_HOST=localhost
KONG_GATEWAY_URL=http://localhost:8000
```

```bash
docker-compose up -d
```

### Escenario 2: LXC Cluster (Producción)

```bash
# .env
KAFKA_BROKERS=192.168.1.51:9092,192.168.1.52:9092
DB_MASTER_HOST=192.168.1.32
DB_SLAVE_HOST=192.168.1.33
KONG_GATEWAY_URL=http://192.168.1.40:8000
```

Deploy en cada LXC según `DEPLOYMENT.md`.

### Escenario 3: Infraestructura en la Nube

```bash
# .env
KAFKA_BROKERS=kafka-1.cloud.example.com:9092,kafka-2.cloud.example.com:9092
DB_MASTER_HOST=mysql-master.rds.amazonaws.com
DB_SLAVE_HOST=mysql-slave.rds.amazonaws.com
KONG_GATEWAY_URL=http://api-gateway.example.com:8000
```

### Escenario 4: Híbrido (On-Premise + Cloud)

```bash
# .env
# Kafka en la nube
KAFKA_BROKERS=kafka.cloud.example.com:9092

# MySQL on-premise
DB_MASTER_HOST=192.168.1.32
DB_SLAVE_HOST=192.168.1.33

# Kong en DMZ
KONG_GATEWAY_URL=http://172.16.0.40:8000
```

---

## 🔒 Seguridad de Red

### Puertos que Deben Estar Abiertos

**Dashboard (LXC 301):**
- **Entrada**: 3000 (API), 8080 (Frontend)
- **Salida**: 3306 (MySQL), 9092 (Kafka), 8000 (Kong)

**MySQL Master/Slave:**
- **Entrada**: 3306 (solo desde Dashboard)

**Kafka:**
- **Entrada**: 9092 (desde Dashboard y otros brokers)

**Kong:**
- **Entrada**: 8000 (desde Dashboard)

### Firewall Rules (UFW)

```bash
# Dashboard
ufw allow 3000/tcp
ufw allow 8080/tcp

# MySQL (solo desde Dashboard)
ufw allow from 192.168.1.31 to any port 3306

# Kafka (solo desde Dashboard)
ufw allow from 192.168.1.31 to any port 9092
```

---

## 🧪 Testing de Conectividad

### Test Automático

```bash
./scripts/test-connectivity.sh
```

**Output esperado:**
```
=== Kafka Cluster ===
Testing Kafka Broker (192.168.1.51:9092)... ✓ OK
Testing Kafka Broker (192.168.1.52:9092)... ✓ OK

=== MySQL Master ===
Testing MySQL Master (192.168.1.32:3306)... ✓ OK

=== MySQL Slave ===
Testing MySQL Slave (192.168.1.33:3306)... ✓ OK

=== Kong Gateway ===
Testing Kong Gateway (http://192.168.1.40:8000)... ✓ OK

✓ All tests passed!
```

### Test Manual

```bash
# Kafka
nc -zv 192.168.1.51 9092

# MySQL
mysql -h 192.168.1.32 -u continental_user -p

# Kong
curl http://192.168.1.40:8000/

# Dashboard Health
curl http://192.168.1.31:3000/health
```

---

## 🔄 Alta Disponibilidad

### Múltiples Instancias del Dashboard

Despliega el dashboard en varios LXC:

**LXC 301 (Principal):**
```bash
KAFKA_GROUP_ID=dashboard-consumer-group
PORT=3000
```

**LXC 304 (Backup):**
```bash
KAFKA_GROUP_ID=dashboard-consumer-group  # Mismo grupo!
PORT=3000
```

Kafka distribuirá automáticamente los eventos entre ambas instancias.

### Load Balancer con NGINX

```nginx
upstream continental_backend {
    server 192.168.1.31:3000 weight=2;
    server 192.168.1.34:3000 backup;
}

server {
    listen 80;
    location /api {
        proxy_pass http://continental_backend;
    }
}
```

---

## 📊 Monitoreo

### Health Checks

```bash
# Dashboard
curl http://192.168.1.31:3000/health

# Respuesta esperada:
{
  "status": "healthy",
  "service": "Continental Dashboard",
  "timestamp": "2025-12-04T..."
}
```

### Logs

```bash
# Ver todos los logs
tail -f logs/app.log

# Solo errores de conexión
tail -f logs/app.log | grep -E "(Error|Failed|Timeout)"

# Solo eventos de Kafka
tail -f logs/app.log | grep "Kafka"
```

---

## 📋 Checklist de Deployment

### Pre-Deployment

- [ ] Copiar archivo `.env` apropiado (`.env.production`)
- [ ] Actualizar todas las IPs en `.env`
- [ ] Actualizar contraseñas de MySQL
- [ ] Configurar frontend (`.env` en `frontend/`)
- [ ] Verificar que todos los servicios externos están corriendo

### Deployment

- [ ] Ejecutar `test-connectivity` script
- [ ] Revisar que todos los tests pasan
- [ ] Configurar firewall rules
- [ ] Instalar dependencias: `npm install`
- [ ] Build frontend: `cd frontend && npm run build`
- [ ] Iniciar backend: `npm start` o `pm2 start`

### Post-Deployment

- [ ] Verificar health endpoint
- [ ] Revisar logs iniciales
- [ ] Test de envío/recepción de eventos Kafka
- [ ] Test de consultas a MySQL
- [ ] Test de llamadas a Kong
- [ ] Configurar monitoreo
- [ ] Documentar IPs específicas usadas

---

## 🛠️ Troubleshooting

### "Cannot connect to Kafka broker"

```bash
# 1. Verificar que Kafka está corriendo
systemctl status kafka  # En el servidor Kafka

# 2. Verificar puerto
netstat -tlnp | grep 9092

# 3. Test de conectividad
telnet 192.168.1.51 9092

# 4. Revisar configuración de Kafka
# advertised.listeners debe ser la IP correcta
```

### "MySQL connection timeout"

```bash
# 1. Verificar bind-address
mysql -u root -p -e "SHOW VARIABLES LIKE 'bind_address';"
# Debe ser 0.0.0.0 o la IP específica

# 2. Verificar firewall
ufw status | grep 3306

# 3. Verificar permisos de usuario
mysql -u root -p -e "SELECT host FROM mysql.user WHERE user='continental_user';"
```

### "Kong returns 502 Bad Gateway"

```bash
# 1. Verificar que App 2 está accesible desde Kong
curl -v http://app2-host:port/health

# 2. Revisar configuración de Kong
curl http://192.168.1.40:8001/services
curl http://192.168.1.40:8001/routes

# 3. Revisar logs de Kong
tail -f /var/log/kong/error.log
```

---

## 📚 Archivos de Configuración

### Backend

- `.env.example` - Template con documentación
- `.env.development` - Desarrollo local
- `.env.staging` - Testing
- `.env.production` - Producción LXC
- `.env` - Archivo activo (gitignored)

### Frontend

- `frontend/.env.production` - Producción
- `frontend/.env.development` - Desarrollo
- `frontend/.env` - Archivo activo

### Scripts

- `scripts/test-connectivity.sh` - Test Linux/macOS
- `scripts/test-connectivity.ps1` - Test Windows
- `scripts/deploy-lxc.sh` - Deploy automático

---

## 🎯 Resumen

### ✅ Lo que YA funciona:

- Conexión a Kafka en IPs diferentes
- Conexión a MySQL Master/Slave distribuidos
- Comunicación con Kong Gateway remoto
- WebSockets para actualizaciones en tiempo real
- Tolerancia a fallos con reintentos exponenciales

### ✅ Lo que necesitas hacer:

1. Copiar archivo `.env` apropiado
2. Actualizar IPs en `.env`
3. Ejecutar script de validación
4. Deploy

### ❌ Lo que NO necesitas hacer:

- ❌ Modificar código
- ❌ Recompilar
- ❌ Cambiar lógica de negocio
- ❌ Actualizar dependencias

**El sistema está 100% preparado para ambiente distribuido.**
