# Continental Dashboard - Guía de Instalación LXC

## Prerequisitos en Proxmox

1. Crear contenedor LXC 301 con:
   - Ubuntu 22.04
   - 2 CPU cores
   - 4GB RAM
   - 20GB storage

## Instalación en LXC 301

### 1. Copiar archivos al contenedor

```bash
# Desde el host Proxmox
pct push 301 /path/to/continental-dashboard /opt/continental-dashboard -r

# Entrar al contenedor
pct enter 301
```

### 2. Ejecutar script de deployment

```bash
cd /opt/continental-dashboard
chmod +x scripts/deploy-lxc.sh
./scripts/deploy-lxc.sh
```

### 3. Configurar variables de entorno

Editar `/opt/continental-dashboard/.env`:

```bash
# Kafka (LXC 501, 502)
KAFKA_BROKERS=192.168.1.51:9092,192.168.1.52:9092

# MySQL Master (LXC 302)
DB_MASTER_HOST=192.168.1.32
DB_MASTER_USER=continental_user
DB_MASTER_PASSWORD=your_secure_password

# MySQL Slave (LXC 303)
DB_SLAVE_HOST=192.168.1.33
DB_SLAVE_USER=continental_user
DB_SLAVE_PASSWORD=your_secure_password

# Kong Gateway (LXC 400)
KONG_GATEWAY_URL=http://192.168.1.40:8000
```

### 4. Configurar como servicio systemd

```bash
cp scripts/continental-dashboard.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable continental-dashboard
systemctl start continental-dashboard
```

### 5. Verificar estado

```bash
systemctl status continental-dashboard
tail -f /var/log/continental-dashboard.log
```

## Configuración de Red

### Firewall (UFW)

```bash
# Permitir salida a Kafka
ufw allow out 9092

# Permitir salida a Kong
ufw allow out 8000

# Permitir salida a MySQL
ufw allow out 3306

# Permitir entrada al dashboard
ufw allow 3000
```

### Verificar conectividad

```bash
# Kafka
telnet lxc-501 9092
telnet lxc-502 9092

# MySQL
telnet lxc-302 3306
telnet lxc-303 3306

# Kong
curl http://lxc-400:8000
```

## Base de Datos

### Inicializar schema en MySQL Master (LXC 302)

```bash
mysql -h lxc-302 -u continental_user -p continental_db < scripts/init-db.sql
```

## Monitoreo

### Logs en tiempo real

```bash
# Logs de aplicación
tail -f /opt/continental-dashboard/logs/continental-dashboard.log

# Logs del sistema
journalctl -u continental-dashboard -f
```

### Health check

```bash
curl http://localhost:3000/health
```

## Acceso al Dashboard

Frontend disponible en:
- Desarrollo: `http://lxc-301:5173`
- Producción: `http://lxc-301:3000`

API endpoints:
- `http://lxc-301:3000/api/v1/dashboard/overview`
- `http://lxc-301:3000/api/v1/metrics/eliminations`
- `http://lxc-301:3000/api/v1/metrics/financials`
- `http://lxc-301:3000/api/v1/metrics/assassins`

## Troubleshooting

### Dashboard no inicia

```bash
# Verificar logs
journalctl -u continental-dashboard -n 50

# Verificar conectividad
ping lxc-501
ping lxc-302
```

### Kafka consumer no conecta

```bash
# Verificar brokers
echo "dump" | nc lxc-501 9092

# Verificar topic
# Desde un broker Kafka:
kafka-topics --list --bootstrap-server localhost:9092
```

### MySQL no conecta

```bash
# Verificar credenciales
mysql -h lxc-302 -u continental_user -p

# Verificar permisos
SHOW GRANTS FOR 'continental_user'@'%';
```

## Actualización

```bash
cd /opt/continental-dashboard
git pull  # o copiar archivos actualizados
npm install
cd frontend && npm install && npm run build && cd ..
systemctl restart continental-dashboard
```

## Backup

```bash
# Backup de configuración
tar -czf continental-backup-$(date +%Y%m%d).tar.gz .env logs/

# Backup de base de datos (en LXC 302)
mysqldump -u continental_user -p continental_db > backup-$(date +%Y%m%d).sql
```
