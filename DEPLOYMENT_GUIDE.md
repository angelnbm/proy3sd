# 📦 Despliegue del Dashboard en LXC 301

## Método Recomendado: Git Clone

### Opción 1: Desde Repositorio Remoto (Recomendado)

```bash
# 1. Entrar al contenedor LXC 301
pct enter 301

# 2. Navegar al directorio de aplicaciones
cd /opt

# 3. Clonar el repositorio
git clone https://github.com/tu-usuario/continental-dashboard.git
# O si usas SSH:
# git clone git@github.com:tu-usuario/continental-dashboard.git

# 4. Entrar al directorio
cd continental-dashboard

# 5. Instalar dependencias del backend
npm install --production

# 6. Instalar dependencias del frontend
cd frontend
npm install
npm run build
cd ..

# 7. Copiar archivo de configuración de producción
cp .env.production .env

# 8. Editar con las IPs reales de tu infraestructura
nano .env

# 9. Iniciar la aplicación
npm start

# O usar PM2 para mantenerlo corriendo:
npm install -g pm2
pm2 start src/index.js --name continental-dashboard
pm2 save
pm2 startup
```

---

### Opción 2: Desde el Host Proxmox (Si no tienes Git remoto)

```bash
# 1. En tu máquina local (donde tienes el código)
# Comprimir el proyecto
cd /ruta/a/tu/proyecto
tar -czf continental-dashboard.tar.gz \
  --exclude='node_modules' \
  --exclude='frontend/node_modules' \
  --exclude='frontend/dist' \
  --exclude='.git' \
  --exclude='logs/*' \
  .

# 2. Copiar al host Proxmox
scp continental-dashboard.tar.gz root@proxmox-host:/tmp/

# 3. En el host Proxmox, copiar al LXC 301
pct push 301 /tmp/continental-dashboard.tar.gz /opt/continental-dashboard.tar.gz

# 4. Entrar al LXC 301
pct enter 301

# 5. Descomprimir
cd /opt
tar -xzf continental-dashboard.tar.gz
mv proy3sd continental-dashboard  # Renombrar si es necesario
cd continental-dashboard

# 6. Instalar dependencias
npm install --production
cd frontend && npm install && npm run build && cd ..

# 7. Configurar .env
cp .env.production .env
nano .env

# 8. Iniciar
npm start
```

---

### Opción 3: Push Directo desde Proxmox Host

```bash
# Si ya tienes el proyecto en el host Proxmox
pct push 301 /ruta/local/proy3sd /opt/continental-dashboard -r

# Luego entrar y configurar
pct enter 301
cd /opt/continental-dashboard
npm install --production
# ... resto de pasos
```

---

## 🔧 Configuración Detallada del .env

Una vez clonado el proyecto, necesitas configurar el archivo `.env`:

```bash
# 1. Copiar template de producción
cp .env.production .env

# 2. Obtener IPs de los servicios
# En el host Proxmox:
pct exec 500 -- hostname -I  # IP Zookeeper
pct exec 501 -- hostname -I  # IP Kafka 1
pct exec 502 -- hostname -I  # IP Kafka 2
pct exec 302 -- hostname -I  # IP MySQL Master
pct exec 303 -- hostname -I  # IP MySQL Slave
pct exec 400 -- hostname -I  # IP Kong Gateway

# 3. Editar .env con las IPs reales
nano /opt/continental-dashboard/.env
```

**Ejemplo de .env configurado:**

```bash
NODE_ENV=production
PORT=3000

# Kafka (usando las IPs reales obtenidas)
KAFKA_BROKERS=10.0.0.101:9092,10.0.0.102:9092
KAFKA_CLIENT_ID=continental-dashboard
KAFKA_GROUP_ID=dashboard-consumer-group
KAFKA_TOPIC=continental.events

# MySQL Master (LXC 302)
DB_MASTER_HOST=10.0.0.32
DB_MASTER_PORT=3306
DB_MASTER_USER=continental_user
DB_MASTER_PASSWORD=tu_password_seguro
DB_MASTER_DATABASE=continental_db

# MySQL Slave (LXC 303)
DB_SLAVE_HOST=10.0.0.33
DB_SLAVE_PORT=3306
DB_SLAVE_USER=continental_user
DB_SLAVE_PASSWORD=tu_password_seguro
DB_SLAVE_DATABASE=continental_db

# Kong Gateway (LXC 400)
KONG_GATEWAY_URL=http://10.0.0.40:8000
CONTRACT_SERVICE_URL=http://10.0.0.40:8000/api/v1/contracts

# Frontend
FRONTEND_URL=http://10.0.0.31:8080

# WebSockets
SOCKET_IO_ENABLED=true

# Tolerancia a fallos
MAX_RETRIES=5
RETRY_DELAY_MS=3000
BACKOFF_MULTIPLIER=2

# Logging
LOG_LEVEL=info
LOG_DIR=/opt/continental-dashboard/logs
```

---

## 📋 Inicializar Base de Datos

```bash
# Dentro del LXC 301
cd /opt/continental-dashboard

# Conectarse al MySQL Master (LXC 302)
mysql -h <IP_MYSQL_MASTER> -u continental_user -p

# Ejecutar el script de inicialización
mysql -h <IP_MYSQL_MASTER> -u continental_user -p continental_db < scripts/init-db.sql
```

---

## 🚀 Opciones para Mantener la Aplicación Corriendo

### Opción A: PM2 (Recomendado)

```bash
# Instalar PM2 globalmente
npm install -g pm2

# Iniciar aplicación
pm2 start src/index.js --name continental-dashboard

# Ver logs
pm2 logs continental-dashboard

# Reiniciar
pm2 restart continental-dashboard

# Detener
pm2 stop continental-dashboard

# Configurar inicio automático
pm2 startup
pm2 save
```

### Opción B: systemd Service

Crear archivo `/etc/systemd/system/continental-dashboard.service`:

```ini
[Unit]
Description=Continental Dashboard
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/continental-dashboard
ExecStart=/usr/bin/node src/index.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Luego:

```bash
systemctl daemon-reload
systemctl enable continental-dashboard
systemctl start continental-dashboard
systemctl status continental-dashboard
```

### Opción C: Docker (Alternativa)

```bash
# Dentro del LXC 301, si prefieres usar Docker
cd /opt/continental-dashboard

# Build de la imagen
docker build -t continental-dashboard .

# Ejecutar
docker run -d \
  --name continental-dashboard \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env \
  continental-dashboard
```

---

## 🧪 Testing Post-Deployment

```bash
# 1. Verificar que el servicio está corriendo
curl http://localhost:3000/health

# Debe retornar:
# {"status":"healthy","service":"Continental Dashboard","timestamp":"..."}

# 2. Test de conectividad a servicios externos
cd /opt/continental-dashboard
./scripts/test-connectivity.sh

# 3. Ver logs en tiempo real
# Si usas PM2:
pm2 logs continental-dashboard

# Si usas systemd:
journalctl -u continental-dashboard -f

# Si ejecutas directamente:
tail -f logs/app.log
```

---

## 🔄 Actualizar el Proyecto

### Desde Git (Recomendado)

```bash
# Entrar al LXC 301
pct enter 301

# Navegar al proyecto
cd /opt/continental-dashboard

# Pull de cambios
git pull origin main  # o la rama correspondiente

# Reinstalar dependencias si hay cambios en package.json
npm install --production
cd frontend && npm install && npm run build && cd ..

# Reiniciar servicio
pm2 restart continental-dashboard
# o
systemctl restart continental-dashboard
```

### Manual

```bash
# Repetir proceso de copiar archivo comprimido
# y reemplazar archivos
```

---

## 📁 Estructura Recomendada en LXC 301

```
/opt/
└── continental-dashboard/
    ├── src/               # Código fuente backend
    ├── frontend/
    │   └── dist/          # Frontend compilado
    ├── logs/              # Archivos de log
    ├── scripts/           # Scripts de utilidad
    ├── .env               # Configuración (NUNCA en Git)
    ├── package.json
    └── node_modules/      # Dependencias

/var/log/
└── continental-dashboard/  # Logs alternativos (opcional)
```

---

## 🔐 Permisos y Seguridad

```bash
# Establecer permisos correctos
chown -R root:root /opt/continental-dashboard
chmod 600 /opt/continental-dashboard/.env  # Proteger credenciales
chmod -R 755 /opt/continental-dashboard
chmod +x /opt/continental-dashboard/scripts/*.sh

# Crear usuario específico (más seguro)
useradd -r -s /bin/false continental
chown -R continental:continental /opt/continental-dashboard
# Luego modificar el service para usar User=continental
```

---

## 🆘 Troubleshooting

### Error: "Cannot find module"

```bash
# Reinstalar dependencias
cd /opt/continental-dashboard
rm -rf node_modules package-lock.json
npm install --production

cd frontend
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Error: "ECONNREFUSED" (No conecta a servicios)

```bash
# Verificar conectividad
./scripts/test-connectivity.sh

# Revisar IPs en .env
cat .env | grep -E "(KAFKA|DB|KONG)"

# Test manual
telnet <IP_KAFKA> 9092
mysql -h <IP_MYSQL> -u continental_user -p
```

### Error: "Port 3000 already in use"

```bash
# Ver qué proceso usa el puerto
lsof -i :3000

# Matar proceso
kill -9 <PID>

# O cambiar puerto en .env
PORT=3001
```

---

## 📊 Monitoreo

```bash
# Ver procesos
pm2 status

# Uso de recursos
pm2 monit

# Logs de errores
pm2 logs --err

# Estadísticas
pm2 show continental-dashboard
```

---

## ✅ Checklist de Deployment

- [ ] LXC 301 creado y corriendo
- [ ] Node.js 20 instalado
- [ ] Git instalado (si usas clone)
- [ ] Proyecto clonado/copiado a `/opt/continental-dashboard`
- [ ] Dependencias instaladas (backend y frontend)
- [ ] Frontend compilado (`npm run build`)
- [ ] Archivo `.env` configurado con IPs correctas
- [ ] Base de datos inicializada en MySQL Master
- [ ] Test de conectividad exitoso
- [ ] Aplicación iniciada (PM2 o systemd)
- [ ] Health check respondiendo
- [ ] Logs mostrando conexión exitosa a Kafka/MySQL
- [ ] Firewall configurado (puertos 3000, 8080)

---

## 🎯 Comando Completo de Deployment

Script todo-en-uno:

```bash
#!/bin/bash
# deploy-dashboard.sh - Ejecutar en LXC 301

set -e

echo "🚀 Desplegando Continental Dashboard..."

# Clonar repositorio
cd /opt
git clone https://github.com/tu-usuario/continental-dashboard.git
cd continental-dashboard

# Instalar dependencias
echo "📦 Instalando dependencias..."
npm install --production
cd frontend && npm install && npm run build && cd ..

# Configurar ambiente
echo "⚙️ Configurando ambiente..."
cp .env.production .env
echo "⚠️  IMPORTANTE: Edita /opt/continental-dashboard/.env con las IPs correctas"

# Instalar PM2
echo "🔧 Instalando PM2..."
npm install -g pm2

# Crear directorio de logs
mkdir -p logs

echo "✅ Instalación completada!"
echo ""
echo "Próximos pasos:"
echo "1. Editar .env: nano /opt/continental-dashboard/.env"
echo "2. Inicializar DB: mysql -h <MYSQL_IP> -u continental_user -p continental_db < scripts/init-db.sql"
echo "3. Test conectividad: ./scripts/test-connectivity.sh"
echo "4. Iniciar app: pm2 start src/index.js --name continental-dashboard"
echo "5. Guardar PM2: pm2 save && pm2 startup"
```

---

**Resumen:** Sí, usa Git clone para desplegar. Es la forma más limpia, permite actualizaciones fáciles con `git pull`, y mantiene control de versiones. 🚀
