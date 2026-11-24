# Estrategia de Copias de Seguridad 3-2-1

## Objetivo

Garantizar la recuperación completa de servicios Docker, bases de datos y configuraciones críticas ante fallo de disco, corrupción lógica o pérdida física de un equipo.

---

## Capas de Almacenamiento

| Capa | Ubicación | Frecuencia | Objetivo |
| :--- | :--- | :--- | :--- |
| **Nivel 1 (Local rápido)** | Disco NVMe secundario / volumen de backups | Diario | Restauración rápida en minutos |
| **Nivel 2 (Réplica local)** | NAS dedicado en red local (SMB/NFS) | Diario | Aislamiento frente a fallo físico del servidor principal |
| **Nivel 3 (Externa cifrada)** | Proveedor cloud vía `rclone crypt` | Diario / Semanal | Protección frente a robo, incendio o ransomware |

---

## Buenas Prácticas Aplicadas

1. **Validación previa de espacio (`check_disk_space`):**  
   Antes de detener contenedores o generar volcados `pg_dump` / archivos `.tar.gz`, se verifica con `df -Pm` que existe un margen mínimo configurable (`MIN_FREE_MB`).
2. **Dumps consistentes de bases de datos:**  
   Las bases de datos PostgreSQL se exportan en caliente mediante `pg_dump` comprimido (`gzip`) en lugar de copiar ficheros binarios en uso.
3. **Exclusión de cachés regenerables:**  
   Directorios de caché de miniaturas, `node_modules`, `__pycache__` y artefactos de compilación se excluyen para reducir tiempo de transferencia y cuota cloud.
4. **Reintentos con espera (`rclone_sync_retry`):**  
   Ante microcortes o límites de API del proveedor cloud, la subida reintenta de forma controlada con pausa entre intentos.
5. **Auditoría diaria:**  
   Un proceso de comprobación revisa la antigüedad de los últimos archivos generados para detectar copias omitidas o desfasadas antes de que sea tarde.
