# Atlas Apps - Helm Charts

Este repositorio contiene **solo los Helm charts** reutilizables para PosLite en RKE2. Los charts se publican en Azure Container Registry (ACR) en formato OCI y se consumen desde el repositorio **atlas-stores**, que es el que Rancher Fleet usa para GitOps.

- **atlas-apps** (este repo): Helm charts + publicación a ACR
- **atlas-stores**: Configuración de despliegue (Fleet bundles, valores por tienda)

## Estructura

```
atlas-apps/
├── charts/
│   ├── poslite-db/                      # PostgreSQL + PgAdmin
│   ├── poslite-core/                    # Core (Portal, WebAPI, Workers)
│   ├── poslite-horustech/               # Servicios Horustech
│   ├── poslite-pam/                     # Servicios PAM
│   ├── poslite-cloudflared/             # Cloudflared tunnel (todos los puertos; legacy)
│   ├── poslite-cloudflared-core/        # Cloudflared: solo Core + BD (10012, 10014, 5050, 5432)
│   ├── poslite-cloudflared-horustech/   # Cloudflared: solo Horustech + BD (901x, 5050, 5432)
│   └── poslite-cloudflared-pam/         # Cloudflared: solo PAM + BD (701x, 5050, 5432)
├── stores/                   # Plantillas de tienda (copiar a atlas-stores)
└── doc/                      # Documentación
```

## Charts Disponibles

### poslite-db

PostgreSQL como StatefulSet con PgAdmin opcional.

**Puertos**:
- PostgreSQL: `hostPort: 5432`
- PgAdmin: `hostPort: 5050`

**Características**:
- StatefulSet para PostgreSQL
- Deployment para PgAdmin
- PVC para persistencia
- ConfigMap para configuración PostgreSQL
- Secret para credenciales

### poslite-core

Stack Core (Portal, WebAPI, Workers con ierp) para **tiendas solo-Core**. No desplegar junto a poslite-pam ni poslite-horustech.

**Puertos**:
- Portal: `hostPort: 10014`
- WebAPI: `hostPort: 10012`

**Características**:
- Deployments para portal y webapi
- Deployments para workers (sin puertos)
- Service ClusterIP para comunicación interna
- PVC para uploads

### poslite-horustech

Stack Horustech **autosuficiente** (incluye portal, webapi, coreWebapi, workers, ierp). Para tiendas Horustech desplegar solo este chart con db y cloudflared-horustech; no desplegar poslite-core.

**Puertos**:
- WebAPI: `hostPort: 9010`
- Core WebAPI: `hostPort: 9012`
- Core Portal: `hostPort: 9014`
- Guard API: `hostPort: 9015`
- Core WebEvents: `hostPort: 9020`
- Loyalty Config Worker: `hostPort: 9021`

**Características**:
- Todos los servicios con hostPort
- Workers sin puertos expuestos
- PVC para uploads, licenses y pointer data

### poslite-pam

Stack PAM **autosuficiente** (incluye portal, coreWebapi, coreWebevents, workers, ierp). Para tiendas PAM desplegar solo este chart con db y cloudflared-pam; no desplegar poslite-core.

**Puertos**:
- TCP Connector: `hostPort: 7010`
- Playwright: `hostPort: 7011`
- Core WebAPI: `hostPort: 7012`
- Core Portal: `hostPort: 7014`
- Guard API: `hostPort: 7015`
- Scraper: `hostPort: 7016`
- Core WebEvents: `hostPort: 7020`

**Características**:
- Todos los servicios con hostPort
- Workers sin puertos expuestos
- PVC para uploads y licenses

### poslite-cloudflared (legacy)

Cloudflared tunnel con todos los puertos (Core, Horustech, PAM, BD). Preferir los charts específicos por stack.

### poslite-cloudflared-core

Cloudflared solo para **Core + BD**: puertos 10012 (WebAPI), 10014 (Portal), 5050 (PgAdmin), 5432 (PostgreSQL).

### poslite-cloudflared-horustech

Cloudflared solo para **Horustech + BD**: puertos 9010, 9012, 9014, 9015, 9020, 9021, 5050, 5432.

### poslite-cloudflared-pam

Cloudflared solo para **PAM + BD**: puertos 7010, 7011, 7012, 7014, 7015, 7016, 7020, 5050, 5432.

**Características (todos los cloudflared)**:
- Deployment con `hostNetwork: true`
- ConfigMap para configuración del tunnel
- Secret para credenciales (opcional)
- Ingress por hostname hacia `localhost:<PUERTO>`

## Despliegue con Fleet (atlas-stores)

Los **Fleet bundles** (qué desplegar y en qué clusters) están en el repositorio **atlas-stores**. Fleet lee ese repo y despliega estos charts desde ACR (`oci://atlashelmrepo.azurecr.io/helm`). No hay bundles en este repositorio.

## Uso

### Desarrollo Local

```bash
# Instalar chart localmente
helm install poslite-db ./charts/poslite-db -n poslite

# Actualizar chart
helm upgrade poslite-db ./charts/poslite-db -n poslite

# Verificar valores
helm template poslite-db ./charts/poslite-db --values values.yaml
```

### Publicar a ACR y desplegar con Fleet

1. **Publicar los charts a ACR**: usa el [workflow de GitHub Actions](.github/workflows/publish-charts.yml) (push a `main`/`master` con cambios en `charts/` o ejecución manual) o la [guía manual](doc/PUBLICAR-CHARTS-ACR.md). Secrets necesarios: `ACR_USERNAME`, `ACR_PASSWORD`.
2. En **atlas-stores** los bundles referencian `oci://atlashelmrepo.azurecr.io/helm` y la versión del chart.
3. Rancher Fleet lee atlas-stores y aplica los despliegues según los labels de los clusters.

## Valores Comunes

Todos los charts aceptan los siguientes valores comunes:

```yaml
imageRegistry: aspposlite.azurecr.io
imageRepository: asptg.com/ierpposlite
imageTag: stable  # stable, latest, unstable

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 200m
    memory: 256Mi

persistence:
  storageClass: local-path

nodeSelector: {}
tolerations: []
affinity: {}
```

## Modelo de despliegue (Core vs PAM vs Horustech)

- **Tiendas solo-Core**: desplegar `poslite-db` + `poslite-core` + `poslite-cloudflared-core`. No desplegar PAM ni Horustech.
- **Tiendas PAM**: desplegar `poslite-db` + `poslite-pam` + `poslite-cloudflared-pam`. **No desplegar poslite-core** (PAM ya incluye portal, coreWebapi, workers e ierp).
- **Tiendas Horustech**: desplegar `poslite-db` + `poslite-horustech` + `poslite-cloudflared-horustech`. **No desplegar poslite-core** (Horustech ya incluye portal, webapi, workers e ierp).

Así se evita duplicar workers (p. ej. ierp) en el mismo cluster.

## Reglas Importantes

1. **NO cambiar puertos**: Los puertos están congelados y deben mantenerse exactamente iguales.

2. **hostPort obligatorio**: Todos los servicios expuestos deben usar `hostPort`.

3. **Cloudflared con hostNetwork**: Cloudflared debe usar `hostNetwork: true` y apuntar a `localhost:<PUERTO>`.

4. **PostgreSQL como StatefulSet**: PostgreSQL debe correr como StatefulSet con PVC local.

5. **Workers sin puertos**: Los workers NO exponen puertos al host.

## Desarrollo

### Agregar un Nuevo Servicio

1. Crear nuevo Deployment en el chart correspondiente
2. Configurar `hostPort` si el servicio debe ser expuesto
3. Agregar variables de entorno necesarias
4. Actualizar values.yaml con valores por defecto
5. Publicar el chart a ACR ([doc/PUBLICAR-CHARTS-ACR.md](doc/PUBLICAR-CHARTS-ACR.md)); en atlas-stores actualizar el bundle si hace falta (p. ej. nueva versión o valores)

### Modificar un Servicio Existente

1. Modificar el template correspondiente
2. Actualizar values.yaml si se agregan nuevos valores
3. Probar localmente con `helm template`
4. Hacer commit, push y publicar el chart a ACR (véase [doc/PUBLICAR-CHARTS-ACR.md](doc/PUBLICAR-CHARTS-ACR.md))
5. Si cambias la versión del chart, actualizar la referencia en atlas-stores; Fleet aplicará los cambios al sincronizar

## Testing

```bash
# Validar sintaxis YAML
helm lint ./charts/poslite-db

# Renderizar templates
helm template poslite-db ./charts/poslite-db --values values.yaml

# Validar con valores de prueba
helm install --dry-run --debug poslite-db ./charts/poslite-db -n poslite
```

## Documentación

- [Publicar charts en ACR](doc/PUBLICAR-CHARTS-ACR.md) — publicación manual y con GitHub Actions.
- [Contexto estructura atlas-stores](doc/CONTEXTO-ESTRUCTURA-ATLAS-STORES.md) — cómo organizar Fleet y bundles por tienda.
- [Qué se crea en Rancher por tienda](doc/RECURSOS-RANCHER-POR-TIENDA.md) — Deployments, StatefulSet, PVCs, Secrets, ConfigMaps por chart y tipo de tienda.
- [Reparar PostgreSQL](doc/REPARAR-POSTGRES.md) — resolución de problemas con poslite-db.

## Contacto

Para problemas o consultas, contactar al equipo de DevOps.
