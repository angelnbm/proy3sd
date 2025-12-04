# 🚀 Quick Start - Desplegar Dashboard en LXC 301

## Método Más Rápido

### Si tienes el código en Git:

```bash
# 1. Entrar al LXC 301
pct enter 301

# 2. Clonar proyecto
cd /opt
git clone https://github.com/tu-usuario/continental-dashboard.git
cd continental-dashboard

# 3. Ejecutar script de deployment
chmod +x scripts/deploy-dashboard.sh
./scripts/deploy-dashboard.sh

# 4. Seguir las instrucciones del script
# - Seleccionar opción 2 (código ya está en servidor)
# - Ingresar IPs de servicios
# - Iniciar aplicación
```

### Si NO tienes Git configurado:

```bash
# 1. En tu máquina local (Windows)
# Comprimir proyecto (excluir node_modules)
tar -czf dashboard.tar.gz ^
  --exclude=node_modules ^
  --exclude=frontend/node_modules ^
  --exclude=frontend/dist ^
  --exclude=.git ^
  --exclude=logs ^
  .

# 2. Copiar a Proxmox Host
scp dashboard.tar.gz root@tu-proxmox:/tmp/

# 3. En Proxmox Host
pct push 301 /tmp/dashboard.tar.gz /tmp/dashboard.tar.gz

# 4. Entrar al LXC 301
pct enter 301

# 5. Descomprimir
cd /opt
tar -xzf /tmp/dashboard.tar.gz
mv proy3sd continental-dashboard  # Renombrar si es necesario
cd continental-dashboard

# 6. Ejecutar script de deployment
chmod +x scripts/deploy-dashboard.sh
./scripts/deploy-dashboard.sh
```

---

## Configuración Manual (Sin script)

```bash
# 1. Ya dentro del LXC 301 con el código
cd /opt/continental-dashboard

# 2. Instalar dependencias
npm install --production
cd frontend && npm install && npm run build && cd ..

# 3. Configurar .env
cp .env.production .env
nano .env
# Editar con las IPs correctas:
# KAFKA_BROKERS=IP1:9092,IP2:9092
# DB_MASTER_HOST=IP_MYSQL
# KONG_GATEWAY_URL=http://IP_KONG:8000

# 4. Inicializar base de datos
mysql -h IP_MYSQL_MASTER -u continental_user -p continental_db < scripts/init-db.sql

# 5. Instalar y configurar PM2
npm install -g pm2
pm2 start src/index.js --name continental-dashboard
pm2 save
pm2 startup

# 6. Verificar
pm2 status
curl http://localhost:3000/health
```

---

## Verificación

```bash
# Health check
curl http://localhost:3000/health

# Ver logs
pm2 logs continental-dashboard

# Status de la app
pm2 status
```

---

## Firewall

```bash
ufw allow 3000/tcp  # API
ufw allow 8080/tcp  # Frontend
ufw enable
```

---

## Estructura Final

```
/opt/continental-dashboard/
├── src/                    # Backend
├── frontend/dist/          # Frontend compilado
├── logs/                   # Logs
├── .env                    # Configuración
├── package.json
└── node_modules/
```

---

## Ver Documentación Completa

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guía completa de deployment
- **[PROXMOX_LXC_SETUP.md](PROXMOX_LXC_SETUP.md)** - Creación de LXC
- **[INFRASTRUCTURE_MAP.md](INFRASTRUCTURE_MAP.md)** - Mapeo de infraestructura
