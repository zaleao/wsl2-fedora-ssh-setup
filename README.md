# Configuración SSH y fail2ban en WSL2 Fedora

Este repositorio contiene la documentación completa para configurar SSH, fail2ban y acceso remoto en un entorno WSL2 con Fedora Linux.

## 📋 Contenido

- **[Configuración Completa](configuracion-ssh-wsl2.md)**: Documentación detallada de toda la configuración
- **[Scripts de Verificación](#scripts)**: Scripts para verificar el estado del sistema
- **[Archivos de Configuración](#archivos)**: Archivos de configuración listos para usar

## 🚀 Inicio Rápido

### Prerrequisitos
- Windows 11 con WSL2 habilitado
- Fedora instalado en WSL2
- Router con capacidad de port forwarding

### Configuración Básica
1. Instalar y configurar SSH en WSL2
2. Configurar fail2ban optimizado para WSL2
3. Configurar port forwarding en Windows
4. Configurar router para acceso externo

### Verificación Rápida
```bash
# Verificar servicios principales
sudo systemctl status sshd
sudo systemctl status fail2ban
sudo fail2ban-client status

# Verificar conectividad
ssh -p 22 localhost -o ConnectTimeout=5
```

## 🔧 Compatibilidad

### ✅ Funciona en:
- **WSL2 con Fedora**: Configuración completa documentada
- **Fedora nativo**: Con simplificaciones (ver documentación)
- **Otras distribuciones Linux**: Adaptable con modificaciones menores

### 📱 Acceso desde:
- **Termux (Android)**: SSH y sFTP funcionando
- **Aplicaciones SSH estándar**: Cualquier cliente SSH
- **Local y remoto**: Acceso desde WiFi local e internet

## 🛡️ Seguridad

- fail2ban configurado para detección de ataques
- Logging personalizado para WSL2
- Port forwarding seguro configurado
- Documentación de resolución de problemas

## 📝 Contribuciones

Este proyecto documenta una configuración específica para WSL2. Si encuentras mejoras o adaptaciones para otros entornos, las contribuciones son bienvenidas.

## 📄 Licencia

Documentación libre para uso personal y educativo.

---

**Autor**: zaleao  
**Fecha**: Septiembre 2025  
**Entorno**: WSL2 Fedora en Windows 11