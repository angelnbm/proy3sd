# 🌐 Configuración para Ambiente Distribuido

## Respuesta Rápida

**SÍ, el proyecto ya funciona en ambiente distribuido con IPs diferentes.** Solo necesitas configurar las variables de entorno.

---

## 🚀 Quick Start

### 1️⃣ Copiar Configuración

```bash
# Para producción (LXC cluster)
cp .env.production .env

# Para desarrollo (local)
cp .env.development .env
```

### 2️⃣ Editar IPs

Abre `.env` y cambia las IPs según tu infraestructura:

```bash
# Kafka Cluster
KAFKA_BROKERS=TU_IP_KAFKA_1:9092,TU_IP_KAFKA_2:9092

# MySQL
DB_MASTER_HOST=TU_IP_MYSQL_MASTER
DB_SLAVE_HOST=TU_IP_MYSQL_SLAVE

# Kong Gateway
KONG_GATEWAY_URL=http://TU_IP_KONG:8000
```

### 3️⃣ Validar Conectividad

```bash
# Linux/macOS
chmod +x scripts/test-connectivity.sh
./scripts/test-connectivity.sh

# Windows PowerShell
.\scripts\test-connectivity.ps1
```

### 4️⃣ Desplegar

```bash
npm install
npm start
```

---

## 📋 Componentes y Sus IPs

| Componente | Puerto | Variable de Entorno |
|------------|--------|---------------------|
| Kafka Broker 1 | 9092 | `KAFKA_BROKERS` (parte 1) |
| Kafka Broker 2 | 9092 | `KAFKA_BROKERS` (parte 2) |
| MySQL Master | 3306 | `DB_MASTER_HOST` |
| MySQL Slave | 3306 | `DB_SLAVE_HOST` |
| Kong Gateway | 8000 | `KONG_GATEWAY_URL` |

---

## 💡 Ejemplos de Configuración

### Red Local (192.168.x.x)

```bash
KAFKA_BROKERS=192.168.1.51:9092,192.168.1.52:9092
DB_MASTER_HOST=192.168.1.32
DB_SLAVE_HOST=192.168.1.33
KONG_GATEWAY_URL=http://192.168.1.40:8000
```

### Red Empresarial (10.x.x.x)

```bash
KAFKA_BROKERS=10.0.0.51:9092,10.0.0.52:9092
DB_MASTER_HOST=10.0.0.32
DB_SLAVE_HOST=10.0.0.33
KONG_GATEWAY_URL=http://10.0.0.40:8000
```

### Nombres de Dominio

```bash
KAFKA_BROKERS=kafka1.miempresa.com:9092,kafka2.miempresa.com:9092
DB_MASTER_HOST=mysql-master.miempresa.com
DB_SLAVE_HOST=mysql-slave.miempresa.com
KONG_GATEWAY_URL=http://api-gateway.miempresa.com:8000
```

### Cloud (AWS, Azure, GCP)

```bash
KAFKA_BROKERS=kafka.example.com:9092
DB_MASTER_HOST=mysql.rds.amazonaws.com
DB_SLAVE_HOST=mysql-slave.rds.amazonaws.com
KONG_GATEWAY_URL=http://api-lb.example.com:8000
```

---

## ✅ Checklist Antes de Desplegar

- [ ] ¿Todos los servicios externos están corriendo?
- [ ] ¿Has actualizado el archivo `.env` con las IPs correctas?
- [ ] ¿El script `test-connectivity` pasa todos los tests?
- [ ] ¿El firewall permite las conexiones necesarias?
- [ ] ¿Has actualizado las contraseñas de MySQL?

---

## 🔥 Comandos Útiles

### Cambiar Rango de Red Completo

```bash
# De 192.168.1.x a 10.0.0.x
sed -i 's/192\.168\.1\./10.0.0./g' .env

# Windows PowerShell
(Get-Content .env) -replace '192\.168\.1\.', '10.0.0.' | Set-Content .env
```

### Ver Configuración Actual

```bash
cat .env | grep -E "(KAFKA|DB|KONG)"
```

### Test de Conectividad Individual

```bash
# Kafka
telnet 192.168.1.51 9092

# MySQL
mysql -h 192.168.1.32 -u continental_user -p

# Kong
curl http://192.168.1.40:8000/
```

---

## 🆘 Problemas Comunes

### ❌ Error: "Cannot connect to Kafka"

**Solución:**
1. Verifica que Kafka está corriendo: `systemctl status kafka`
2. Verifica el puerto: `netstat -tlnp | grep 9092`
3. Prueba conexión: `telnet IP_KAFKA 9092`

### ❌ Error: "MySQL connection refused"

**Solución:**
1. Verifica bind-address en MySQL:
   ```sql
   SHOW VARIABLES LIKE 'bind_address';
   ```
   Debe ser `0.0.0.0` o la IP específica
2. Verifica firewall: `ufw allow from IP_DASHBOARD to any port 3306`

### ❌ Error: "Kong timeout"

**Solución:**
1. Verifica que Kong puede alcanzar App 2
2. Revisa rutas de Kong: `curl http://IP_KONG:8001/routes`

---

## 📖 Documentación Detallada

- **`README_DISTRIBUTED.md`** - Guía completa de arquitectura distribuida
- **`MULTI_ENV_SETUP.md`** - Configuración multi-ambiente
- **`DISTRIBUTED_SETUP.md`** - Setup paso a paso
- **`DEPLOYMENT.md`** - Guía de instalación LXC

---

## 🎯 Resumen

✅ **Tu proyecto YA está listo para ambiente distribuido**

✅ **Solo necesitas actualizar las IPs en `.env`**

✅ **No requiere cambios en el código**

✅ **Incluye scripts de validación automática**

---

**¿Dudas?** Revisa los archivos `.env.example` y `README_DISTRIBUTED.md`
