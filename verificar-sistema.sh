#!/bin/bash

# Script de Verificación del Sistema SSH/fail2ban en WSL2
# Autor: zaleao
# Fecha: Septiembre 2025

echo "🔍 VERIFICACIÓN DEL SISTEMA SSH/FAIL2BAN EN WSL2"
echo "=================================================="
echo

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar OK/ERROR
show_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ ERROR${NC}"
    fi
}

echo -e "${BLUE}1. Verificando SSH...${NC}"
echo -n "   Estado del servicio SSH: "
sudo systemctl is-active sshd > /dev/null 2>&1
show_status

echo -n "   Puerto SSH 22 escuchando: "
sudo ss -tlnp | grep :22 > /dev/null 2>&1
show_status

echo -n "   Conexión SSH local: "
ssh -p 22 localhost -o ConnectTimeout=3 -o BatchMode=yes "echo SSH-OK" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ERROR${NC}"
fi

echo

echo -e "${BLUE}2. Verificando fail2ban...${NC}"
echo -n "   Estado del servicio fail2ban: "
sudo systemctl is-active fail2ban > /dev/null 2>&1
show_status

echo -n "   Jails activos: "
JAILS=$(sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | xargs)
if [ -n "$JAILS" ]; then
    echo -e "${GREEN}✅ OK (${JAILS})${NC}"
else
    echo -e "${YELLOW}⚠️  No hay jails activos${NC}"
fi

echo -n "   Estado jail sshd: "
sudo fail2ban-client status sshd > /dev/null 2>&1
show_status

echo

echo -e "${BLUE}3. Verificando red WSL2...${NC}"
echo -n "   Conectividad a Windows: "
ping -c 1 -W 2 10.255.255.254 > /dev/null 2>&1
show_status

echo -n "   Conectividad a Internet: "
ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1
show_status

echo -n "   Dirección IP WSL2: "
IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -n "$IP" ]; then
    echo -e "${GREEN}✅ ${IP}${NC}"
else
    echo -e "${RED}❌ No detectada${NC}"
fi

echo

echo -e "${BLUE}4. Verificando Port Forwarding Windows...${NC}"
echo -n "   Puerto 2222 escuchando en Windows: "
/mnt/c/Windows/System32/netstat.exe -an 2>/dev/null | grep :2222 > /dev/null
show_status

echo -n "   Reglas de port forwarding: "
RULES=$(/mnt/c/Windows/System32/netsh.exe interface portproxy show all 2>/dev/null | grep -c "172.24")
if [ "$RULES" -gt 0 ]; then
    echo -e "${GREEN}✅ ${RULES} reglas activas${NC}"
else
    echo -e "${RED}❌ No hay reglas${NC}"
fi

echo

echo -e "${BLUE}5. Logs recientes...${NC}"
echo "   Últimas entradas de fail2ban personalizado:"
if [ -f /var/log/fail2ban-custom.log ]; then
    tail -3 /var/log/fail2ban-custom.log 2>/dev/null | while read line; do
        echo -e "   ${YELLOW}📝${NC} $line"
    done
else
    echo -e "   ${YELLOW}⚠️  Archivo de log personalizado no encontrado${NC}"
fi

echo

echo -e "${BLUE}6. Comandos útiles:${NC}"
echo "   • Ver estado SSH: sudo systemctl status sshd"
echo "   • Ver estado fail2ban: sudo fail2ban-client status"
echo "   • Ver logs fail2ban: sudo tail -f /var/log/fail2ban.log"
echo "   • Ver logs personalizados: sudo tail -f /var/log/fail2ban-custom.log"
echo "   • Probar SSH local: ssh -p 22 localhost"
echo "   • Ver port forwarding: /mnt/c/Windows/System32/netsh.exe interface portproxy show all"

echo
echo "=================================================="
echo -e "${GREEN}Verificación completada$(date)${NC}"