# Tienda Core para Raspberry Pi (Pi 5 16GB)

Plantilla para una tienda **solo Core** desplegada en un cluster sobre **Raspberry Pi 5 16GB** (4 cores ARM, 16 GB RAM). Los recursos en el `fleet.yaml` están ajustados para este hardware.

## Labels del cluster (en Rancher)

- `atlas: "true"`
- `store: "tienda-core-ejemplo-rpi"` (o el ID de tu tienda al renombrar)

## Requisitos en el cluster Pi

1. **StorageClass:** debe existir (p. ej. `local-path`). Ver doc sobre provisioner si el cluster no tiene ninguna.
2. **Imágenes:** el registry debe ofrecer imágenes para **ARM64** (RKE2 en Pi 5 suele ser 64 bits).

## Cómo usar en atlas-stores

1. Copia esta carpeta a `atlas-stores/fleet/bundles/stores/`.
2. Renómbrala al ID de tu tienda (ej: `mi-tienda-pi`) y en `fleet.yaml` sustituye `tienda-core-ejemplo-rpi` por ese ID en `clusterSelector` y en los hostnames de cloudflared.
3. Asigna al cluster las labels `atlas: "true"` y `store: <id-tienda>`.

Más detalles: [doc/DESPLIEGUE-RASPBERRY-PI.md](../../doc/DESPLIEGUE-RASPBERRY-PI.md).
