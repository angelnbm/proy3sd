# Continental Dashboard - Arquitectura Técnica

## Visión General

El Dashboard Ejecutivo Continental (Aplicación 3) es el **cerebro orquestador** del sistema distribuido, responsable de:

1. **Consumir eventos de Kafka** desde la App 1
2. **Orquestar el cierre de contratos** comunicándose con la App 2 vía Kong Gateway
3. **Implementar tolerancia a fallos** con reintentos exponenciales
4. **Proveer visualización ejecutiva** para la High Table
5. **Generar reportes** con datos históricos

---

## Stack Tecnológico

### Backend
- **Runtime**: Node.js 20
- **Framework**: Express 4.18
- **ORM**: Sequelize 6
- **Mensajería**: KafkaJS 2.2
- **HTTP Client**: Axios
- **WebSockets**: Socket.io 4.6
- **Logging**: Winston 3

### Frontend
- **Framework**: Vue.js 3
- **UI Library**: Vuetify 3
- **Charts**: Chart.js 4
- **HTTP Client**: Axios
- **Real-time**: Socket.io-client

### Base de Datos
- **DBMS**: MySQL 8.0
- **Patrón**: Master/Slave Replication
- **Master** (LXC 302): Escrituras
- **Slave** (LXC 303): Lecturas

### Infraestructura
- **Contenedor**: LXC 301 (Proxmox)
- **Gateway**: Kong API Gateway (LXC 400)
- **Message Broker**: Kafka (LXC 501, 502)

---

## Arquitectura de Componentes

```
┌─────────────────────────────────────────────────┐
│           Frontend (Vue.js + Vuetify)           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │Dashboard │  │Analytics │  │ Reports  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
└────────────┬────────────────────────────────────┘
             │ HTTP/WebSocket
             ▼
┌─────────────────────────────────────────────────┐
│           Backend (Express API)                 │
│  ┌──────────────────────────────────────────┐  │
│  │         Routes & Controllers              │  │
│  └──────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────┐  │
│  │         Services & Repositories           │  │
│  └──────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────┐  │
│  │    Kafka Consumer (Event Handler)        │  │
│  └──────────────────────────────────────────┘  │
└─────┬────────────────────────────┬──────────────┘
      │                            │
      │ Kafka Events               │ HTTP (Kong)
      ▼                            ▼
┌──────────────┐           ┌──────────────┐
│   Kafka      │           │  App 2       │
│ (501, 502)   │           │ (Contracts)  │
└──────────────┘           └──────────────┘
      │
      │ DB Queries
      ▼
┌──────────────┐           ┌──────────────┐
│ MySQL Master │───────────│ MySQL Slave  │
│   (LXC 302)  │Replication│  (LXC 303)   │
└──────────────┘           └──────────────┘
```

---

## Flujo de Eventos Crítico

### 1. Eliminación Verificada → Cierre de Contrato

```
┌─────────┐     ┌─────────┐     ┌──────────┐     ┌─────────┐
│  App 1  │────▶│  Kafka  │────▶│Dashboard │────▶│  Kong   │
│ (Verify)│     │ (Event) │     │(Consumer)│     │(Gateway)│
└─────────┘     └─────────┘     └──────────┘     └─────────┘
                                      │                │
                                      │                ▼
                                      │           ┌─────────┐
                                      │           │  App 2  │
                                      │           │(Contract)│
                                      │           └─────────┘
                                      │                │
                                      │                │ Success
                                      ▼                ▼
                                 ┌──────────┐    ┌──────────┐
                                 │  MySQL   │    │  Kafka   │
                                 │ (Master) │    │ (Commit) │
                                 └──────────┘    └──────────┘
                                      │
                                      ▼
                                 ┌──────────┐
                                 │WebSocket │
                                 │Broadcast │
                                 └──────────┘
```

### Pasos Detallados:

1. **Evento recibido**: Kafka consumer recibe `EliminationVerified`
2. **Validación**: Extraer `contractId`, `assassinId`, `coinsAmount`
3. **Orquestación**: POST a Kong Gateway → App 2 para cerrar contrato
4. **Retry Logic**: Si falla, reintenta con backoff exponencial
5. **No Commit**: Si falla después de max reintentos, NO confirma mensaje
6. **Persistencia**: Guarda eliminación en MySQL Master
7. **Actualización**: Update métricas de contrato
8. **Notificación**: Broadcast vía WebSocket a clientes conectados
9. **Commit**: Confirma offset en Kafka

---

## Base de Datos: Read/Write Splitting

### Patrón de Conexión

```javascript
// Escrituras → Master (LXC 302)
const masterConnection = new Sequelize({
  host: 'lxc-302',
  database: 'continental_db'
});

// Lecturas → Slave (LXC 303)
const slaveConnection = new Sequelize({
  host: 'lxc-303',
  database: 'continental_db'
});
```

### Reglas de Routing

| Operación | Destino | Razón |
|-----------|---------|-------|
| INSERT | Master | Consistencia inmediata |
| UPDATE | Master | Evitar conflictos |
| DELETE | Master | Integridad referencial |
| SELECT (Dashboard) | Slave | Reducir carga en master |
| SELECT (Reports) | Slave | Queries pesadas |
| SELECT (Metrics) | Slave | Alta concurrencia |

### Beneficios

✅ **Performance**: Descarga lecturas del nodo principal  
✅ **Escalabilidad**: Múltiples slaves para leer  
✅ **SLO Compliance**: Reportes < 2s (usando slave optimizado)  
✅ **Alta Disponibilidad**: Slave puede promover a master  

---

## Tolerancia a Fallos

### Retry Logic para Kong/App 2

```javascript
MAX_RETRIES = 5
RETRY_DELAY = 3000ms
BACKOFF_MULTIPLIER = 2

Intento 1: 3000ms delay
Intento 2: 6000ms delay
Intento 3: 12000ms delay
Intento 4: 24000ms delay
Intento 5: 48000ms delay

Total: ~93 segundos de reintentos
```

### Garantías de Consistencia

- **At-Least-Once Delivery**: Kafka no confirma offset hasta éxito
- **Idempotencia**: App 2 debe manejar duplicados de cierre de contrato
- **Eventual Consistency**: El sicario siempre recibe su pago (eventualmente)

---

## Requisitos No Funcionales (SLOs)

| Métrica | SLO | Implementación |
|---------|-----|----------------|
| Carga Dashboard | < 2s | Lecturas en Slave + índices optimizados |
| Actualización Métricas | < 5s | WebSocket push + polling 5s |
| Disponibilidad | 99.9% | Retry logic + health checks |
| Procesamiento Eventos | < 1s | Kafka consumer con auto-commit manual |
| Generación Reportes | < 3s | Queries optimizadas en Slave |

---

## Seguridad

### Consideraciones Actuales

⚠️ **Pendiente de Implementación**:
- Autenticación JWT para API
- HTTPS/TLS en todas las comunicaciones
- Encriptación de credenciales en `.env`
- RBAC para acceso a endpoints
- Rate limiting por IP

### Recomendaciones

1. **Kong Gateway**: Implementar API key authentication
2. **Kafka**: Habilitar SASL/SCRAM authentication
3. **MySQL**: Usar SSL para conexiones
4. **WebSocket**: Implementar token-based auth

---

## Monitoreo y Observabilidad

### Logs Estructurados (Winston)

```javascript
logger.info('Event processed', { 
  contractId: 'CNT-001',
  duration: '1.2s',
  retry: 0 
});
```

### Métricas Clave

- **Eventos procesados/min**
- **Tiempo promedio de procesamiento**
- **Tasa de reintentos**
- **Errores de conexión a App 2**
- **Latencia de queries a MySQL**

### Health Checks

```bash
GET /health
{
  "status": "healthy",
  "service": "Continental Dashboard",
  "timestamp": "2024-12-04T10:30:00.000Z"
}
```

---

## Escalabilidad

### Actual (LXC 301)
- 2 CPU cores
- 4GB RAM
- ~100 eventos/min
- ~50 usuarios concurrentes

### Escalabilidad Horizontal

Para crecer:

1. **Kafka Consumer Group**: Múltiples instancias del dashboard
2. **Load Balancer**: Nginx delante de múltiples LXCs
3. **Read Replicas**: Más slaves de MySQL para reportes
4. **Caching**: Redis para métricas frecuentes

---

## Próximos Pasos

### Fase 1: Funcionalidad Core ✅
- [x] Kafka consumer
- [x] Orquestación con App 2
- [x] Dashboard básico
- [x] Reportes

### Fase 2: Robustez
- [ ] Implementar circuit breaker
- [ ] Dead letter queue para eventos fallidos
- [ ] Alertas automáticas
- [ ] Backup automático de MySQL

### Fase 3: Seguridad
- [ ] JWT authentication
- [ ] HTTPS/TLS
- [ ] Rate limiting
- [ ] Audit logs

### Fase 4: Performance
- [ ] Redis caching
- [ ] Query optimization
- [ ] CDN para frontend
- [ ] Horizontal scaling

---

## Referencias

- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Sequelize Replication](https://sequelize.org/docs/v6/other-topics/read-replication/)
- [Kong Gateway](https://docs.konghq.com/)
- [Vue.js 3](https://vuejs.org/)
- [Chart.js](https://www.chartjs.org/)
