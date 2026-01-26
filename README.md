# Atlas Apps - Plantillas y Charts Helm

Este repositorio contiene todos los recursos reutilizables para el despliegue de PosLite en RKE2:
- Helm Charts parametrizables
- Fleet Bundles para GitOps

## Estructura

```
atlas-apps/
├── charts/
│   ├── poslite-db/          # PostgreSQL + PgAdmin
│   ├── poslite-core/        # Core (Portal, WebAPI, Workers)
│   ├── poslite-horustech/   # Servicios Horustech
│   ├── poslite-pam/         # Servicios PAM
│   └── poslite-cloudflared/  # Cloudflared tunnel
└── fleet/
    └── bundles/
        ├── db/
        ├── core/
        ├── horustech/
        ├── pam/
        └── cloudflared/
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

Servicios Core de PosLite (Portal, WebAPI, Workers).

**Puertos**:
- Portal: `hostPort: 10014`
- WebAPI: `hostPort: 10012`

**Características**:
- Deployments para portal y webapi
- Deployments para workers (sin puertos)
- Service ClusterIP para comunicación interna
- PVC para uploads

### poslite-horustech

Servicios específicos de Horustech.

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

Servicios específicos de PAM.

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

### poslite-cloudflared

Cloudflared tunnel para conectividad externa.

**Características**:
- Deployment con `hostNetwork: true`
- ConfigMap para configuración del tunnel
- Secret para credenciales
- Apunta a `localhost:<PUERTO>` para cada servicio

## Fleet Bundles

Los bundles de Fleet definen cómo se despliegan los charts según los labels de los clusters.

### db Bundle

Despliega PostgreSQL en todos los clusters con label `atlas: "true"`.

### core Bundle

Despliega servicios Core en todos los clusters con label `atlas: "true"`.

### horustech Bundle

Despliega servicios Horustech en clusters con labels:
- `atlas: "true"`
- `poslite: "horustech"`

### pam Bundle

Despliega servicios PAM en clusters con labels:
- `atlas: "true"`
- `poslite: "pam"`

### cloudflared Bundle

Despliega Cloudflared en todos los clusters con label `atlas: "true"`.

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

### Con Fleet

Fleet leerá automáticamente los bundles y los aplicará según los labels de los clusters.

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
5. Actualizar bundle de Fleet si es necesario

### Modificar un Servicio Existente

1. Modificar el template correspondiente
2. Actualizar values.yaml si se agregan nuevos valores
3. Probar localmente con `helm template`
4. Hacer commit y push
5. Fleet aplicará los cambios automáticamente

## Testing

```bash
# Validar sintaxis YAML
helm lint ./charts/poslite-db

# Renderizar templates
helm template poslite-db ./charts/poslite-db --values values.yaml

# Validar con valores de prueba
helm install --dry-run --debug poslite-db ./charts/poslite-db -n poslite
```

## Contacto

Para problemas o consultas, contactar al equipo de DevOps.
