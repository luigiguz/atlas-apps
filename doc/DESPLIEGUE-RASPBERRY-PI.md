# Despliegue en Raspberry Pi (Pi 5 16GB)

Los charts están ajustados por defecto para entornos con recursos limitados (p. ej. **Raspberry Pi 5 16GB**: 4 cores ARM, 16 GB RAM). En Pi conviene además reducir replicas y, en PAM, valorar desactivar Playwright si no lo necesitas.

## Recursos por defecto en los charts (desde atlas-apps)

| Chart / componente | Límites (CPU / memoria) | Requests |
|--------------------|-------------------------|----------|
| **poslite-db** (Postgres) | 500m / 768Mi | 250m / 384Mi |
| **poslite-db** (PgAdmin) | 100m / 128Mi | 50m / 64Mi |
| **poslite-core**, **poslite-pam**, **poslite-horustech** (por contenedor) | 400m / 384Mi | 50m / 128Mi |
| **poslite-pam** (Playwright) | 500m / 512Mi | 250m / 256Mi |
| **poslite-cloudflared-*** | 200m / 128Mi | 100m / 64Mi |

Con estos valores, una tienda Core (db + core + cloudflared) cabe en ~14 GB RAM y ~3,5 cores; en Pi 5 16GB deja margen para el sistema.

## Opción A: Usar la plantilla de tienda para Pi (recomendado)

En **atlas-apps/stores/** hay una plantilla lista para Pi:

- **tienda-core-ejemplo-rpi**: misma estructura que `tienda-core-ejemplo` pero con overrides de recursos y notas para Pi.

Copia la carpeta `tienda-core-ejemplo-rpi` a **atlas-stores/fleet/bundles/stores/** (o renómbrala a tu tienda). El `fleet.yaml` ya incluye `resources` y `persistence` adecuados para Pi. Ajusta `store` y hostnames al ID de tu tienda.

## Opción B: Overrides manuales en atlas-stores (fleet.yaml)

Si usas una tienda existente y solo quieres bajar recursos para el cluster Pi, añade en el **fleet.yaml** del bundle los bloques `resources` (y, en PAM, `playwright.enabled` o `playwright.resources`) en cada target.

### Target `db` (poslite-db)

```yaml
- name: db
  clusterSelector:
    matchLabels:
      atlas: "true"
      store: "tu-tienda"
  helm:
    chart: poslite-db
    repo: oci://atlashelmrepo.azurecr.io/helm
    version: 1.0.0
    values:
      persistence:
        enabled: true
        storageClass: local-path   # o la StorageClass que exista en el cluster
        size: 20Gi
        accessMode: ReadWriteOnce
      resources:
        limits:
          cpu: 500m
          memory: 768Mi
        requests:
          cpu: 250m
          memory: 384Mi
      pgadmin:
        enabled: true
        resources:
          limits:
            cpu: 100m
            memory: 128Mi
          requests:
            cpu: 50m
            memory: 64Mi
      postgresql:
        timezone: "America/Panama"
        database: poslite
        user: sa
```

### Target `core` (poslite-core)

```yaml
- name: core
  ...
  helm:
    chart: poslite-core
    ...
    values:
      resources:
        limits:
          cpu: 400m
          memory: 384Mi
        requests:
          cpu: 50m
          memory: 128Mi
      portal:
        enabled: true
        replicas: 1
      webapi:
        enabled: true
        replicas: 1
      workers:
        price: { enabled: true }
        shift: { enabled: true }
        errorReports: { enabled: true }
        ierp: { enabled: true }
```

### Target `pam` (poslite-pam) — en Pi, desactivar Playwright si no se usa

```yaml
- name: pam
  ...
  helm:
    chart: poslite-pam
    ...
    values:
      resources:
        limits:
          cpu: 400m
          memory: 384Mi
        requests:
          cpu: 50m
          memory: 128Mi
      playwright:
        enabled: false   # recomendado en Pi si no usas Playwright
        # Si lo dejas true, por defecto ya usa 500m/512Mi (configurable con playwright.resources)
```

### Target `cloudflared-*`

Los charts cloudflared ya usan 200m/128Mi; no suele hacer falta override. Si quieres bajar más:

```yaml
values:
  resources:
    limits:
      cpu: 100m
      memory: 64Mi
    requests:
      cpu: 50m
      memory: 32Mi
```

## Requisitos en el cluster Pi

1. **StorageClass:** debe existir una StorageClass (p. ej. `local-path`) para que los PVC de Postgres y PgAdmin se provisionen. Si el cluster no tiene ninguna, instala un provisioner (p. ej. [Rancher local-path-provisioner](https://github.com/rancher/local-path-provisioner)).
2. **Labels del cluster:** `atlas: "true"` y `store: <id-tienda>`.
3. **Imágenes:** los registros de imágenes deben ofrecer imagen para **ARM64** si el Pi corre a 64 bits (RKE2 en Pi 5 suele ser arm64).

## Resumen

- **Opción A:** Usar la plantilla **stores/tienda-core-ejemplo-rpi** en atlas-stores (copiar y ajustar store/hostnames).
- **Opción B:** En el fleet.yaml de tu tienda, añadir los bloques `resources` (y `playwright.enabled: false` en PAM si aplica) como arriba.

Los valores por defecto de los charts ya están pensados para entornos limitados; en servidores más grandes puedes sobrescribir en fleet con `resources` más altos (p. ej. Postgres 1000m/2Gi, Playwright 2000m/2Gi).
