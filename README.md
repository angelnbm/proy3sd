# Continental Dashboard - Aplicación 3

Dashboard Ejecutivo Continental - Cerebro orquestador del sistema distribuido.

> 🌐 **¿Necesitas configurar IPs diferentes?** Ver **[DISTRIBUTED_IPS.md](DISTRIBUTED_IPS.md)** para quick start

## Arquitectura

- **Backend**: Node.js 20 + Express 4.18
- **Frontend**: Vue.js 3 + Vuetify + Chart.js
- **Base de Datos**: MySQL 8.0 (Master/Slave)
- **Mensajería**: Apache Kafka
- **Gateway**: Kong API Gateway
- **Infraestructura**: LXC 301 (Proxmox) - **100% distribuible**

## Responsabilidades

1. **Consumidor de Eventos Kafka**: Escucha eventos de eliminación verificada
2. **Orquestador**: Coordina el cierre de contratos con App 2 vía Kong Gateway
3. **Tolerancia a Fallos**: Sistema de reintentos para garantizar consistencia
4. **Dashboard Ejecutivo**: Visualización en tiempo real para la High Table
5. **Reportes**: Generación de reportes ejecutivos

## Instalación

```bash
# Instalar dependencias del backend
npm install

# Instalar dependencias del frontend
cd frontend
npm install
cd ..
```

## Configuración

### Ambiente Distribuido (Producción)

```bash
# 1. Copiar configuración de producción
cp .env.production .env

# 2. Editar IPs según tu infraestructura
nano .env

# 3. Validar conectividad
./scripts/test-connectivity.sh  # Linux/macOS
.\scripts\test-connectivity.ps1  # Windows
```

**Ver [DISTRIBUTED_IPS.md](DISTRIBUTED_IPS.md) para guía completa de configuración con IPs diferentes.**

### Ambiente Local (Desarrollo)

```bash
# 1. Copiar configuración de desarrollo
cp .env.development .env

# 2. Levantar servicios con Docker
docker-compose up -d
```

### Variables Críticas

Asegurar conectividad con:
- **Kafka brokers**: `KAFKA_BROKERS=IP1:9092,IP2:9092`
- **MySQL Master**: `DB_MASTER_HOST=IP_MASTER`
- **MySQL Slave**: `DB_SLAVE_HOST=IP_SLAVE`
- **Kong Gateway**: `KONG_GATEWAY_URL=http://IP_KONG:8000`

## Ejecución

### Desarrollo
```bash
# Backend
npm run dev

# Frontend (en otra terminal)
npm run frontend:dev
```

### Producción
```bash
# Build frontend
npm run frontend:build

# Start backend
npm start
```

## Endpoints API

- `GET /api/v1/dashboard/overview` - Vista principal del dashboard
- `GET /api/v1/dashboard/reports` - Reportes ejecutivos
- `POST /api/v1/dashboard/alerts` - Configuración de alertas
- `GET /api/v1/metrics/eliminations` - Métricas de eliminaciones
- `GET /api/v1/metrics/financials` - Métricas financieras
- `GET /api/v1/metrics/assassins` - Eficiencia de sicarios

## Flujo de Eventos

1. App 1 publica evento `EliminationVerified` en Kafka
2. Dashboard consume el evento
3. Dashboard envía POST a App 2 vía Kong para cerrar contrato
4. Si falla, reintenta con backoff exponencial
5. Una vez exitoso, actualiza métricas en MySQL
6. Frontend se actualiza vía WebSocket

## SLOs

- Tiempo de carga de reportes: < 2 segundos
- Actualización de métricas: < 5 segundos
- Disponibilidad: 99.9%

## Configuración LXC

En el contenedor LXC 301:

```bash
# Instalar Node.js 20 con NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20

# Configurar firewall
ufw allow out 9092  # Kafka
ufw allow out 8000  # Kong
ufw allow out 3306  # MySQL
ufw allow 3000      # Dashboard
```

## Monitoreo

Logs disponibles en:
- `logs/continental-dashboard.log` - Logs de aplicación
- `logs/kafka-consumer.log` - Logs de consumidor Kafka
- `logs/errors.log` - Logs de errores

## Documentación Adicional

### 🚀 Setup y Deployment
- **[INFRASTRUCTURE_MAP.md](INFRASTRUCTURE_MAP.md)** - 🗺️ **Mapeo de LXC a crear en Proxmox**
- **[PROXMOX_LXC_SETUP.md](PROXMOX_LXC_SETUP.md)** - Guía completa de creación de contenedores
- **[DISTRIBUTED_IPS.md](DISTRIBUTED_IPS.md)** - Quick start para configurar IPs diferentes
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Guía de instalación paso a paso

### 📚 Arquitectura y Configuración
- **[README_DISTRIBUTED.md](README_DISTRIBUTED.md)** - Guía completa de arquitectura distribuida
- **[MULTI_ENV_SETUP.md](MULTI_ENV_SETUP.md)** - Configuración multi-ambiente
- **[DISTRIBUTED_SETUP.md](DISTRIBUTED_SETUP.md)** - Setup detallado paso a paso
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Arquitectura técnica
- **[API.md](API.md)** - Documentación de endpoints
