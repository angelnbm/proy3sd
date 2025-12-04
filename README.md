# Continental Dashboard - Aplicación 3

Dashboard Ejecutivo Continental - Cerebro orquestador del sistema distribuido.

## Arquitectura

- **Backend**: Node.js 20 + Express 4.18
- **Frontend**: Vue.js 3 + Vuetify + Chart.js
- **Base de Datos**: MySQL 8.0 (Master/Slave)
- **Mensajería**: Apache Kafka
- **Gateway**: Kong API Gateway
- **Infraestructura**: LXC 301 (Proxmox)

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

1. Copiar `.env.example` a `.env`
2. Configurar las variables de entorno según tu infraestructura LXC
3. Asegurar conectividad con:
   - Kafka brokers (LXC 501, 502)
   - MySQL Master (LXC 302)
   - MySQL Slave (LXC 303)
   - Kong Gateway (LXC 400)

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
