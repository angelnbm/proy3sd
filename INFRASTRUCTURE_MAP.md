# 🗺️ Mapeo Completo de Infraestructura Continental

## 📊 Tu Infraestructura Actual vs Necesaria

### ✅ Contenedores Existentes (Apps 1 y 2)

| LXC | Nombre | App | Tipo | Base de Datos |
|-----|--------|-----|------|---------------|
| **112** | App1-Principal | App 1 | Backend Principal | MariaDB (113) |
| **113** | MariaDB-Master | App 1 | Base de Datos Master | - |
| **114** | MariaDB-Slave | App 1 | Base de Datos Slave | - |
| **115** | App1-Replica | App 1 | Backend Replica | MariaDB (113/114) |
| **116** | Orchestrator-DB1 | App 1 | Orchestrator | - |
| **400** | nginx/Gateway | Shared | Kong Gateway | - |
| **601** | App2-Principal | App 2 | Backend Principal | Postgres (603) |
| **602** | App2-Replica | App 2 | Backend Replica | Postgres (603/604) |
| **603** | Postgres-Master | App 2 | Base de Datos Master | - |
| **604** | Postgres-Slave | App 2 | Base de Datos Slave | - |
| **605** | Patron-Etcd | App 2 | Etcd | - |

**Total Existentes: 11 LXC**

---

### ⭐ Contenedores a Crear (App 3 - Dashboard)

| LXC | Nombre | App | Tipo | Propósito | Prioridad |
|-----|--------|-----|------|-----------|-----------|
| **500** | Zookeeper | App 3 | Coordinación | Gestión cluster Kafka | 🔴 CRÍTICO |
| **501** | Kafka-Broker-1 | App 3 | Message Broker | Eventos entre apps | 🔴 CRÍTICO |
| **502** | Kafka-Broker-2 | App 3 | Message Broker | HA para Kafka | 🟡 Recomendado |
| **302** | MySQL-Master | App 3 | Base de Datos | Escrituras Dashboard | 🔴 CRÍTICO |
| **303** | MySQL-Slave | App 3 | Base de Datos | Lecturas Dashboard | 🟡 Recomendado |
| **301** | Dashboard-Principal | App 3 | Backend + Frontend | App principal | 🔴 CRÍTICO |
| **304** | Dashboard-Replica | App 3 | Backend + Frontend | HA Dashboard | 🟢 Opcional |

**Total a Crear: 7 LXC (4 críticos, 2 recomendados, 1 opcional)**

---

## 🔗 Diagrama de Conexiones Completo

```
┌────────────────────────────────────────────────────────────────────────────┐
│                           PROXMOX HOST                                      │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  APP 1 - Verificación de Eliminaciones ✅ EXISTENTE                  │ │
│  │                                                                       │ │
│  │  ┌─────────────┐  ┌─────────────┐                                   │ │
│  │  │ LXC 112     │  │ LXC 115     │                                   │ │
│  │  │ App1-Princ  │  │ App1-Replica│                                   │ │
│  │  └──────┬──────┘  └──────┬──────┘                                   │ │
│  │         │                │                                           │ │
│  │         └────────┬───────┘                                           │ │
│  │                  │                                                   │ │
│  │         ┌────────▼────────┐       ┌─────────────┐                   │ │
│  │         │ LXC 113         │◄──────│ LXC 114     │                   │ │
│  │         │ MariaDB-Master  │Master/│ MariaDB-Slav│                   │ │
│  │         └────────┬────────┘Slave  └─────────────┘                   │ │
│  │                  │                                                   │ │
│  │                  │ Publica eventos de eliminación                    │ │
│  │                  ▼                                                   │ │
│  └──────────────────┼───────────────────────────────────────────────────┘ │
│                     │                                                     │
│  ┌──────────────────▼─────────────────────────────────────────────────┐  │
│  │  KAFKA CLUSTER ⭐ NUEVO                                            │  │
│  │                                                                     │  │
│  │  ┌─────────────┐                                                   │  │
│  │  │ LXC 500     │  Coordina cluster Kafka                           │  │
│  │  │ Zookeeper   │                                                   │  │
│  │  └──────┬──────┘                                                   │  │
│  │         │                                                           │  │
│  │  ┌──────▼──────┐       ┌─────────────┐                            │  │
│  │  │ LXC 501     │◄─────►│ LXC 502     │                            │  │
│  │  │ Kafka-Br-1  │ Sync  │ Kafka-Br-2  │                            │  │
│  │  └──────┬──────┘       └──────┬──────┘                            │  │
│  │         │                     │                                    │  │
│  │         └──────────┬──────────┘                                    │  │
│  │                    │ Topic: continental.events                     │  │
│  │                    ▼                                                │  │
│  └────────────────────┼─────────────────────────────────────────────────┘ │
│                       │                                                   │
│  ┌────────────────────▼─────────────────────────────────────────────────┐ │
│  │  APP 3 - DASHBOARD CONTINENTAL ⭐ NUEVO                             │ │
│  │                                                                       │ │
│  │  ┌─────────────┐       ┌─────────────┐                             │ │
│  │  │ LXC 301     │       │ LXC 304     │ (Opcional)                   │ │
│  │  │ Dashboard-P │       │ Dashboard-R │                             │ │
│  │  │             │◄─────►│             │ Mismo consumer group         │ │
│  │  │ - Backend   │       │ - Backend   │                             │ │
│  │  │ - Frontend  │       │ - Frontend  │                             │ │
│  │  │ - Kafka Con.│       │ - Kafka Con.│                             │ │
│  │  └──────┬──────┘       └──────┬──────┘                             │ │
│  │         │                     │                                     │ │
│  │         └──────────┬──────────┘                                     │ │
│  │                    │                                                │ │
│  │         ┌──────────▼──────────┐                                     │ │
│  │         │                     │                                     │ │
│  │  ┌──────▼──────┐       ┌──────▼──────┐                             │ │
│  │  │ LXC 302     │◄──────│ LXC 303     │                             │ │
│  │  │ MySQL-Mast. │Master/│ MySQL-Slave │                             │ │
│  │  │ (Escrituras)│Slave  │ (Lecturas)  │                             │ │
│  │  └──────┬──────┘       └─────────────┘                             │ │
│  │         │                                                           │ │
│  └─────────┼───────────────────────────────────────────────────────────┘ │
│            │                                                             │
│            │ Orquesta cierre de contratos                               │
│            ▼                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │  KONG API GATEWAY ✅ EXISTENTE                                      │ │
│  │                                                                      │ │
│  │  ┌─────────────┐                                                    │ │
│  │  │ LXC 400     │  Proxy + Rate Limiting + Auth                      │ │
│  │  │ nginx/Kong  │                                                    │ │
│  │  └──────┬──────┘                                                    │ │
│  │         │                                                            │ │
│  └─────────┼────────────────────────────────────────────────────────────┘ │
│            │                                                              │
│            ▼                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │  APP 2 - Gestión de Contratos ✅ EXISTENTE                          │ │
│  │                                                                      │ │
│  │  ┌─────────────┐  ┌─────────────┐       ┌─────────────┐            │ │
│  │  │ LXC 601     │  │ LXC 602     │       │ LXC 605     │            │ │
│  │  │ App2-Princ  │  │ App2-Replica│       │ Patron-Etcd │            │ │
│  │  └──────┬──────┘  └──────┬──────┘       └─────────────┘            │ │
│  │         │                │                                          │ │
│  │         └────────┬───────┘                                          │ │
│  │                  │                                                  │ │
│  │         ┌────────▼────────┐       ┌─────────────┐                  │ │
│  │         │ LXC 603         │◄──────│ LXC 604     │                  │ │
│  │         │ Postgres-Master │Master/│ Postgres-Slv│                  │ │
│  │         └─────────────────┘Slave  └─────────────┘                  │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Tabla Resumen de Todos los LXC

| LXC | Nombre | App | Stack | CPU | RAM | Disco | Estado |
|-----|--------|-----|-------|-----|-----|-------|--------|
| 112 | App1-Principal | 1 | Backend | 2 | 4GB | 20GB | ✅ Existe |
| 113 | MariaDB-Master | 1 | DB | 2 | 4GB | 30GB | ✅ Existe |
| 114 | MariaDB-Slave | 1 | DB | 2 | 4GB | 30GB | ✅ Existe |
| 115 | App1-Replica | 1 | Backend | 2 | 4GB | 20GB | ✅ Existe |
| 116 | Orchestrator-DB1 | 1 | Orchestrator | 1 | 2GB | 10GB | ✅ Existe |
| **301** | **Dashboard-Principal** | **3** | **Node.js** | **2** | **4GB** | **20GB** | **⭐ Crear** |
| **302** | **MySQL-Master** | **3** | **DB** | **2** | **4GB** | **30GB** | **⭐ Crear** |
| **303** | **MySQL-Slave** | **3** | **DB** | **2** | **4GB** | **30GB** | **⭐ Crear** |
| **304** | **Dashboard-Replica** | **3** | **Node.js** | **2** | **4GB** | **20GB** | **⭐ Crear** |
| 400 | nginx/Gateway | Shared | Kong | 2 | 4GB | 20GB | ✅ Existe |
| **500** | **Zookeeper** | **3** | **ZK** | **1** | **2GB** | **10GB** | **⭐ Crear** |
| **501** | **Kafka-Broker-1** | **3** | **Kafka** | **2** | **6GB** | **30GB** | **⭐ Crear** |
| **502** | **Kafka-Broker-2** | **3** | **Kafka** | **2** | **6GB** | **30GB** | **⭐ Crear** |
| 601 | App2-Principal | 2 | Backend | 2 | 4GB | 20GB | ✅ Existe |
| 602 | App2-Replica | 2 | Backend | 2 | 4GB | 20GB | ✅ Existe |
| 603 | Postgres-Master | 2 | DB | 2 | 4GB | 30GB | ✅ Existe |
| 604 | Postgres-Slave | 2 | DB | 2 | 4GB | 30GB | ✅ Existe |
| 605 | Patron-Etcd | 2 | Etcd | 1 | 2GB | 10GB | ✅ Existe |

**Total: 18 LXC (11 existentes + 7 nuevos)**

---

## 🎯 Plan de Creación Priorizado

### Fase 1: Infraestructura Base (CRÍTICO) 🔴

```bash
# Crear en este orden:
1. LXC 500 - Zookeeper       (Kafka lo necesita)
2. LXC 501 - Kafka Broker 1  (Dashboard lo necesita)
3. LXC 302 - MySQL Master    (Dashboard lo necesita)
4. LXC 301 - Dashboard       (Aplicación principal)
```

**Tiempo estimado: 2-3 horas**

### Fase 2: Alta Disponibilidad (RECOMENDADO) 🟡

```bash
# Agregar redundancia:
5. LXC 502 - Kafka Broker 2  (HA para Kafka)
6. LXC 303 - MySQL Slave     (Lecturas + backup)
```

**Tiempo estimado: 1-2 horas**

### Fase 3: Redundancia Completa (OPCIONAL) 🟢

```bash
# Completar HA:
7. LXC 304 - Dashboard Replica  (HA total)
```

**Tiempo estimado: 30 minutos**

---

## 💾 Recursos Totales Necesarios

### Configuración Mínima (Fase 1)
- **LXC**: 4 nuevos
- **CPU**: 7 cores
- **RAM**: 16 GB
- **Disco**: 90 GB

### Configuración Completa (Todas las Fases)
- **LXC**: 7 nuevos
- **CPU**: 13 cores
- **RAM**: 32 GB
- **Disco**: 170 GB

### Infraestructura Total (Con Apps 1 y 2)
- **LXC**: 18 contenedores
- **CPU**: ~33 cores
- **RAM**: ~70 GB
- **Disco**: ~450 GB

---

## 🚀 Scripts de Automatización Disponibles

### 1. Crear Contenedores

```bash
# En Proxmox Host
chmod +x scripts/create-lxc-containers.sh
./scripts/create-lxc-containers.sh
```

**Opciones:**
- Infraestructura Completa (7 LXC)
- Infraestructura Mínima (4 LXC)
- Solo Kafka + Zookeeper (3 LXC)
- Solo Dashboard + MySQL (3 LXC)

### 2. Instalar Software

```bash
# En Proxmox Host
chmod +x scripts/install-lxc-software.sh
./scripts/install-lxc-software.sh
```

**Instala:**
- Node.js 20 (LXC 301, 304)
- MySQL 8.0 (LXC 302, 303)
- Kafka (LXC 501, 502)
- Zookeeper (LXC 500)

---

## 🔌 Puertos y Conectividad

### Puertos a Configurar

| LXC | Servicio | Puerto | Acceso Desde |
|-----|----------|--------|--------------|
| 500 | Zookeeper | 2181 | 501, 502 |
| 501 | Kafka | 9092 | 112, 115, 301, 304 |
| 502 | Kafka | 9092 | 112, 115, 301, 304 |
| 302 | MySQL | 3306 | 301, 304 |
| 303 | MySQL | 3306 | 301, 304 |
| 301 | Dashboard API | 3000 | Internet/Frontend |
| 301 | Dashboard UI | 8080 | Internet |
| 304 | Dashboard API | 3000 | Load Balancer |
| 400 | Kong | 8000 | 301, 304 |

---

## 🔗 Integración con Apps Existentes

### App 1 (LXC 112, 115) → Kafka

Modificar configuración de App 1:

```env
# Agregar en .env de App 1
KAFKA_ENABLED=true
KAFKA_BROKERS=<IP_501>:9092,<IP_502>:9092
KAFKA_TOPIC=continental.events
```

Cuando se verifique una eliminación, App 1 publicará:

```json
{
  "eventType": "EliminationVerified",
  "contractId": "CTR-12345",
  "assassinId": "ASS-67890",
  "targetId": "TGT-54321",
  "verificationDate": "2025-12-04T10:30:00Z"
}
```

### Kong (LXC 400) ← Dashboard

Kong ya existe, solo asegurar que:
- Tiene ruta configurada para App 2
- Dashboard (LXC 301) puede alcanzarlo
- Rate limiting configurado

---

## ✅ Checklist Final

### Pre-Creación
- [ ] Verificar recursos disponibles en Proxmox
- [ ] Descargar template Ubuntu 22.04
- [ ] Planificar IPs (DHCP o estáticas)
- [ ] Revisar almacenamiento disponible

### Creación
- [ ] Ejecutar script de creación de LXC
- [ ] Anotar IPs asignadas
- [ ] Ejecutar script de instalación de software
- [ ] Verificar que todos los servicios arrancan

### Configuración
- [ ] Configurar replicación MySQL (302 → 303)
- [ ] Configurar cluster Kafka (501, 502 → 500)
- [ ] Crear base de datos en MySQL
- [ ] Crear topic en Kafka
- [ ] Configurar firewall en cada LXC

### Deployment
- [ ] Clonar código en LXC 301
- [ ] Actualizar `.env` con IPs reales
- [ ] Ejecutar test de conectividad
- [ ] Iniciar Dashboard
- [ ] Verificar consumo de eventos Kafka
- [ ] Verificar comunicación con Kong/App2

### Testing
- [ ] Test de publicación de eventos desde App 1
- [ ] Test de consumo en Dashboard
- [ ] Test de orquestación a App 2
- [ ] Test de failover (si HA configurado)
- [ ] Test de performance

---

## 📞 Próximos Pasos

1. **Revisar recursos de Proxmox**: ¿Tienes ~16GB RAM y ~100GB disco libres?
2. **Decidir configuración**: ¿Mínima (4 LXC) o Completa (7 LXC)?
3. **Ejecutar scripts**: `create-lxc-containers.sh` → `install-lxc-software.sh`
4. **Configurar servicios**: MySQL replication, Kafka cluster
5. **Desplegar Dashboard**: Código + `.env` con IPs
6. **Integrar con App 1**: Configurar publicación de eventos

**Ver guías detalladas en:**
- `PROXMOX_LXC_SETUP.md` - Instrucciones paso a paso
- `DISTRIBUTED_IPS.md` - Configuración de IPs
- `README_DISTRIBUTED.md` - Arquitectura completa
