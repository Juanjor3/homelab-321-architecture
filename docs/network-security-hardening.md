# Endurecimiento de Red y Contenedores

## 1. Perímetro y DNS

- **DNS-over-TLS (DoT):** Todo el tráfico DNS saliente se cifra hacia resolvedores upstream de confianza para evitar inspección o manipulación en tránsito.
- **Filtrado de listas de amenazas:** Bloqueo preventivo a nivel de firewall/DNS frente a rangos maliciosos conocidos y dominios de tracking/C2.
- **Cero exposición directa innecesaria:** Los servicios internos no abren puertos directos en el router; el acceso remoto se canaliza mediante túneles **VPN** cifrados.

---

## 2. Buenas Prácticas en Docker Compose

- **Principio de mínimo privilegio:**
  - Montar sockets o carpetas de configuración en modo solo lectura (`:ro`) siempre que el contenedor no necesite escribir.
  - Evitar `privileged: true` en servicios de aplicación.
- **Control de recursos y discos:**
  - Configurar siempre rotación de logs:
    ```yaml
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    ```
  - Definir `deploy.resources.limits.memory` para prevenir que una fuga de memoria afecte al resto del host.
- **Healthchecks:**
  - Incorporar comprobación `healthcheck` nativa en cada servicio crítico para detectar procesos bloqueados aunque el contenedor siga levantado.
