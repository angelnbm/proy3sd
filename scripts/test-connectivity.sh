#!/bin/bash

# ======================================================
# Continental Dashboard - Test de Conectividad
# ======================================================
# Este script valida la conectividad a todos los 
# servicios distribuidos del sistema.
# ======================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  Continental Dashboard"
echo "  Connectivity Test"
echo "=========================================="
echo ""

# Cargar variables de entorno
if [ -f .env ]; then
  source .env
else
  echo -e "${RED}Error: .env file not found${NC}"
  exit 1
fi

# Función para test TCP
test_tcp() {
  local host=$1
  local port=$2
  local name=$3
  
  echo -n "Testing $name ($host:$port)... "
  
  if timeout 3 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
    echo -e "${GREEN}✓ OK${NC}"
    return 0
  else
    echo -e "${RED}✗ FAILED${NC}"
    return 1
  fi
}

# Función para test HTTP
test_http() {
  local url=$1
  local name=$2
  
  echo -n "Testing $name ($url)... "
  
  if curl -s -f -m 3 "$url" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
    return 0
  else
    echo -e "${RED}✗ FAILED${NC}"
    return 1
  fi
}

failures=0

# ========== KAFKA ==========
echo -e "${YELLOW}=== Kafka Cluster ===${NC}"
IFS=',' read -ra BROKERS <<< "$KAFKA_BROKERS"
for broker in "${BROKERS[@]}"; do
  # Remover espacios
  broker=$(echo $broker | xargs)
  # Separar host:port
  host=${broker%%:*}
  port=${broker##*:}
  
  test_tcp "$host" "$port" "Kafka Broker" || ((failures++))
done
echo ""

# ========== MySQL Master ==========
echo -e "${YELLOW}=== MySQL Master ===${NC}"
test_tcp "$DB_MASTER_HOST" "${DB_MASTER_PORT:-3306}" "MySQL Master" || ((failures++))
echo ""

# ========== MySQL Slave ==========
echo -e "${YELLOW}=== MySQL Slave ===${NC}"
test_tcp "$DB_SLAVE_HOST" "${DB_SLAVE_PORT:-3306}" "MySQL Slave" || ((failures++))
echo ""

# ========== Kong Gateway ==========
echo -e "${YELLOW}=== Kong Gateway ===${NC}"
test_http "${KONG_GATEWAY_URL}" "Kong Gateway" || ((failures++))

# También test del servicio de contratos
if [ -n "$CONTRACT_SERVICE_URL" ]; then
  test_http "${CONTRACT_SERVICE_URL}" "Contract Service" || ((failures++))
fi
echo ""

# ========== DNS Resolution ==========
echo -e "${YELLOW}=== DNS Resolution ===${NC}"

# Probar resolver cada host
for host in "$DB_MASTER_HOST" "$DB_SLAVE_HOST"; do
  echo -n "Resolving $host... "
  if nslookup "$host" > /dev/null 2>&1 || getent hosts "$host" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
  else
    echo -e "${RED}✗ FAILED${NC}"
    ((failures++))
  fi
done

# Probar Kafka hosts
for broker in "${BROKERS[@]}"; do
  host=${broker%%:*}
  host=$(echo $host | xargs)
  echo -n "Resolving $host... "
  if nslookup "$host" > /dev/null 2>&1 || getent hosts "$host" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
  else
    echo -e "${RED}✗ FAILED${NC}"
    ((failures++))
  fi
done
echo ""

# ========== Resumen ==========
echo "=========================================="
if [ $failures -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  echo "The system is ready to operate."
  exit 0
else
  echo -e "${RED}✗ $failures test(s) failed${NC}"
  echo "Please check network configuration and service availability."
  exit 1
fi
