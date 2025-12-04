#!/bin/bash

# Continental Dashboard - Deployment Script for LXC 301
# This script sets up the dashboard on Proxmox LXC container

set -e

echo "=== Continental Dashboard Deployment ==="
echo "Target: LXC 301 - Proxmox"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Install Node.js 20 via NVM
echo -e "${GREEN}[1/7] Installing Node.js 20 via NVM...${NC}"
if ! command -v nvm &> /dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi
nvm install 20
nvm use 20
echo "Node version: $(node --version)"

# Step 2: Install dependencies
echo -e "${GREEN}[2/7] Installing backend dependencies...${NC}"
npm install

echo -e "${GREEN}[3/7] Installing frontend dependencies...${NC}"
cd frontend
npm install
cd ..

# Step 3: Build frontend
echo -e "${GREEN}[4/7] Building frontend...${NC}"
cd frontend
npm run build
cd ..

# Step 4: Create environment file
echo -e "${GREEN}[5/7] Setting up environment configuration...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please edit .env file with your configuration!${NC}"
fi

# Step 5: Create necessary directories
echo -e "${GREEN}[6/7] Creating directories...${NC}"
mkdir -p logs
mkdir -p frontend/dist

# Step 6: Configure firewall
echo -e "${GREEN}[7/7] Configuring firewall rules...${NC}"
echo "Allowing outbound connections:"
echo "  - Kafka (9092)"
echo "  - Kong Gateway (8000)"
echo "  - MySQL (3306)"
echo "  - Dashboard (3000)"

# Uncomment if you want to auto-configure UFW
# ufw allow out 9092 comment "Kafka"
# ufw allow out 8000 comment "Kong Gateway"
# ufw allow out 3306 comment "MySQL"
# ufw allow 3000 comment "Dashboard HTTP"

echo ""
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your LXC configuration"
echo "2. Ensure connectivity to:"
echo "   - Kafka brokers (LXC 501, 502)"
echo "   - MySQL Master (LXC 302)"
echo "   - MySQL Slave (LXC 303)"
echo "   - Kong Gateway (LXC 400)"
echo "3. Run: npm start"
echo ""
echo "For development: npm run dev"
echo "For production: Use PM2 or systemd service"
echo ""
