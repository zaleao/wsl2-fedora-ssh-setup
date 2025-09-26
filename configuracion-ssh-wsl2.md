# Configuración SSH, fail2ban y Acceso Remoto en WSL2 Fedora

## Información del Sistema
- **Sistema Host**: Windows 11
- **WSL2**: Fedora Linux 42
- **Kernel WSL**: 6.6.87.2-microsoft-standard-WSL2
- **Router**: 5G con port forwarding
- **Fecha de configuración**: Septiembre 2025

---

## 📋 Tabla de Contenidos

1. [Configuración de Red](#configuración-de-red)
2. [Configuración SSH](#configuración-ssh)
3. [Configuración fail2ban](#configuración-fail2ban)
4. [Port Forwarding](#port-forwarding)
5. [Acceso Remoto](#acceso-remoto)
6. [Resolución de Problemas](#resolución-de-problemas)
7. [Comandos de Verificación](#comandos-de-verificación)
8. [Notas para Fedora Nativo](#notas-para-fedora-nativo)

---

## 🌐 Configuración de Red

### Arquitectura de Red Actual
```
Internet/Móvil → Router 5G → Windows 11 → WSL2 Fedora
```

### Direcciones IP
- **Router 5G Gateway**: 192.168.1.1
- **Windows 11**: 192.168.1.100 (IP estática reservada)
- **WSL2 Fedora**: 172.24.133.148/20 (dinámica)
- **WSL2 Gateway**: 172.24.128.1
- **Windows desde WSL2**: 10.255.255.254

### Verificación de Red WSL2
```bash
# Ver configuración de red
ip addr show

# Ver rutas
ip route show

# Probar conectividad a Windows
ping -c 3 10.255.255.254

# Probar conectividad a internet
ping -c 3 8.8.8.8
```

---

## 🔐 Configuración SSH

### Estado del Servicio
```bash
# Verificar estado SSH
sudo systemctl status sshd

# Habilitar SSH en arranque
sudo systemctl enable sshd

# Reiniciar SSH
sudo systemctl restart sshd
```

### Configuración del Servidor SSH
**Archivo**: `/etc/ssh/sshd_config`

**Configuraciones importantes aplicadas**:
- Puerto: **22** (estándar)
- Autenticación por contraseña: Habilitada
- Root login: Configurado según necesidades
- Protocolo: SSH-2

### Puertos en Escucha
```bash
# Verificar puertos SSH activos
sudo ss -tlnp | grep :22
# Resultado esperado: LISTEN 0.0.0.0:22 y [::]:22
```

---

## 🛡️ Configuración fail2ban

### Problema Identificado en WSL2
- **Firewalld no funciona** en WSL2 por limitaciones del kernel
- **iptables limitados** en entorno virtualizado
- **Solución**: Configuración solo para alertas y logging

### Configuración Optimizada para WSL2
**Archivo**: `/etc/fail2ban/jail.d/sshd.local`

```ini
# Configuración de fail2ban para SSH - Versión Simple para WSL2
# Solo logging, sin intentos de bloqueo de red

[sshd]
# Habilitar el jail para SSH
enabled = true

# Puerto SSH personalizado
port = 2222

# Configuración de detección
maxretry = 5
bantime = 3600      # 1 hora
findtime = 600      # 10 minutos

# Backend para leer logs (systemd funciona bien en WSL2)
backend = systemd

# ACCIÓN SIMPLE PARA WSL2
# Solo registrar en logs, sin bloqueo real
# Esto es útil para monitoreo y estadísticas
action = dummy[actionban=echo "FAIL2BAN-WSL2: Banned IP <ip> for attacking SSH on port 2222 at $(date)" >> /var/log/fail2ban-custom.log,
              actionunban=echo "FAIL2BAN-WSL2: Unbanned IP <ip> after bantime expired at $(date)" >> /var/log/fail2ban-custom.log]
```

### Log Personalizado
```bash
# Crear archivo de log personalizado
sudo touch /var/log/fail2ban-custom.log
sudo chmod 644 /var/log/fail2ban-custom.log

# Ver logs personalizados en tiempo real
sudo tail -f /var/log/fail2ban-custom.log
```

### Comandos de Gestión fail2ban
```bash
# Estado general
sudo fail2ban-client status

# Estado específico del jail SSH
sudo fail2ban-client status sshd

# Reiniciar fail2ban
sudo systemctl restart fail2ban

# Ver logs de fail2ban
sudo tail -f /var/log/fail2ban.log
```

### Funcionalidad en WSL2
✅ **Lo que funciona**:
- Detección de ataques SSH
- Logging de eventos
- Estadísticas de intentos
- Alertas y notificaciones

❌ **Lo que NO funciona** (por diseño):
- Bloqueo real de IPs (firewall)
- iptables/nftables avanzados

---

## 🔄 Port Forwarding

### Configuración del Router 5G
- **Puerto externo**: 2222
- **Puerto interno**: 22  
- **IP interna**: 192.168.1.100
- **Protocolo**: TCP
- **Servicio**: SSH

### Port Forwarding en Windows
**Comandos ejecutados en PowerShell como administrador**:

```powershell
# Eliminar configuración previa si existe
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0

# Configurar port forwarding específico
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=192.168.1.100 connectport=22 connectaddress=172.24.133.148

# Verificar configuración
netsh interface portproxy show all

# Configurar firewall de Windows
netsh advfirewall firewall add rule name="SSH-WSL2-2222" dir=in action=allow protocol=TCP localport=2222
```

### Verificación Port Forwarding
```bash
# Desde WSL2 - verificar que Windows escucha en 2222
/mnt/c/Windows/System32/netstat.exe -an | grep :2222
# Resultado esperado: TCP 0.0.0.0:2222 LISTENING

# Probar conexión local a puerto 2222
ssh -p 2222 10.255.255.254 -o ConnectTimeout=5
```

---

## 📱 Acceso Remoto

### Desde Termux (Móvil en WiFi local)
```bash
# SSH local
ssh -p 2222 usuario@192.168.1.100

# sFTP local  
sftp -P 2222 usuario@192.168.1.100
```

### Desde Internet (Datos móviles/Externa)
```bash
# SSH externo
ssh -p 2222 usuario@TU_IP_PUBLICA

# sFTP externo
sftp -P 2222 usuario@TU_IP_PUBLICA
```

### Cadena de Conexión Completa
```
Cliente → Router(2222) → Windows(192.168.1.100:2222) → WSL2(172.24.133.148:22)
```

---

## 🔧 Resolución de Problemas

### Problemas Comunes y Soluciones

#### 1. **"Connection refused" en SSH**
```bash
# Verificar que SSH está corriendo
sudo systemctl status sshd

# Verificar puertos
sudo ss -tlnp | grep :22

# Reiniciar SSH si es necesario
sudo systemctl restart sshd
```

#### 2. **fail2ban con errores de firewall**
**Error común en WSL2**: `FirewallD is not running`

**Solución**: Usar configuración solo para logging (ya implementada)

#### 3. **Port forwarding no funciona**
```powershell
# En PowerShell como administrador
netsh interface portproxy show all

# Si no aparece la regla, reconfigurar
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=192.168.1.100 connectport=22 connectaddress=172.24.133.148
```

#### 4. **Ping no funciona pero SSH sí**
**Es normal**: Windows bloquea ICMP (ping) por defecto, pero permite TCP (SSH).

**Para habilitar ping (opcional)**:
```powershell
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
```

---

## ✅ Comandos de Verificación

### Lista de Verificación Rápida
```bash
# 1. Estado SSH
sudo systemctl status sshd

# 2. Puerto SSH activo
sudo ss -tlnp | grep :22

# 3. Estado fail2ban
sudo fail2ban-client status

# 4. Port forwarding Windows
/mnt/c/Windows/System32/netsh.exe interface portproxy show all

# 5. Puerto 2222 escuchando en Windows
/mnt/c/Windows/System32/netstat.exe -an | grep :2222

# 6. Conectividad local WSL2
ssh -p 22 localhost -o ConnectTimeout=5 -o BatchMode=yes

# 7. Logs de fail2ban personalizado
sudo tail -5 /var/log/fail2ban-custom.log

# 8. Red WSL2
ip addr show eth0
```

### Estado Esperado ✅
- **SSH**: `active (running)`
- **fail2ban**: `1 jail activo (sshd)`
- **Port forwarding**: `2 reglas activas (22 y 2222)`
- **Windows puerto 2222**: `LISTENING`
- **Conectividad**: SSH local y remoto funcionando

---

## 🐧 Notas para Fedora Nativo

### Diferencias en Fedora Nativo
Cuando migres a Fedora nativo, estas serán las **simplificaciones**:

#### **Configuración de Red**
- ✅ **Acceso directo** a la red 192.168.1.x
- ✅ **Sin port forwarding** Windows necesario
- ✅ **firewalld funciona** completamente

#### **fail2ban en Nativo**
```ini
[sshd]
enabled = true
port = 22  # o 2222 según preferencia
maxretry = 5
bantime = 3600
findtime = 600
# En nativo SÍ funciona el bloqueo real:
action = %(action_mwl)s
destemail = tu_correo@example.com
```

#### **Port Forwarding Simplificado**
Solo en el router: `Puerto_externo → Fedora_IP:22`

#### **Comandos Adicionales Disponibles**
```bash
# firewalld (funciona en nativo)
sudo firewall-cmd --list-all

# Bloqueos reales de fail2ban
sudo fail2ban-client status sshd  # Verá IPs realmente bloqueadas
```

---

## 📝 Notas Finales

### ✅ **Configuración Actual Exitosa**
- **SSH/sFTP**: Funcionando local y remoto
- **fail2ban**: Optimizado para WSL2 (logging)
- **Seguridad**: Port forwarding configurado correctamente
- **Acceso móvil**: Termux conecta sin problemas

### 🔮 **Para el Futuro (Equipo IA con Fedora Nativo)**
- Misma base de configuración
- Simplificación de port forwarding
- fail2ban con bloqueo real
- Mejor rendimiento general
- Acceso directo al hardware

### 📚 **Conocimiento Transferible**
- Gestión de servicios systemd
- Configuración SSH avanzada  
- Troubleshooting de conectividad
- Seguridad de acceso remoto
- Administración de logs

---

**Documento actualizado**: 26 de septiembre de 2025  
**Autor**: Configuración colaborativa  
**Entorno**: WSL2 Fedora en Windows 11