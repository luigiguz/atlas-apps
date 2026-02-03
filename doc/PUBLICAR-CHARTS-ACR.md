# Publicar Helm charts en Azure Container Registry (ACR)

Los charts de PosLite se publican en ACR en formato OCI y se consumen desde **atlas-stores** vía Fleet con `oci://atlashelmrepo.azurecr.io/helm`.

## Charts que se publican

| Chart | Descripción |
|-------|-------------|
| poslite-db | PostgreSQL + PgAdmin |
| poslite-core | Core (Portal, WebAPI, Workers) |
| poslite-pam | Stack PAM completo |
| poslite-horustech | Stack Horustech completo |
| poslite-cloudflared-core | Cloudflared Core + BD |
| poslite-cloudflared-pam | Cloudflared PAM + BD |
| poslite-cloudflared-horustech | Cloudflared Horustech + BD |

## Opción 1: GitHub Actions (recomendado)

El workflow `.github/workflows/publish-charts.yml` se ejecuta:

- **Automáticamente** al hacer push a `main` o `master` cuando cambian archivos en `charts/`.
- **Manualmente** desde la pestaña Actions → "Publish Helm charts to ACR" → "Run workflow".

### Secrets necesarios en el repositorio

En GitHub: Settings → Secrets and variables → Actions, configura:

| Secret | Descripción |
|--------|-------------|
| `ACR_USERNAME` | Usuario del registry (ej. nombre del ACR) |
| `ACR_PASSWORD` | Contraseña o token del ACR |

El registry por defecto es `atlashelmrepo.azurecr.io`. Para usar otro, edita `env.ACR_REGISTRY` en el workflow.

## Opción 2: Publicación manual desde tu máquina

Desde la raíz del repo (o desde `charts/`):

```powershell
# 1. Ir al directorio de charts
cd "C:\ruta\atlas-apps\charts"

# 2. Login en ACR
helm registry login atlashelmrepo.azurecr.io
# Username: <tu-usuario-acr>
# Password: <tu-password>

# 3. Empaquetar y publicar cada chart
helm package poslite-db
helm push poslite-db-1.0.0.tgz oci://atlashelmrepo.azurecr.io/helm

helm package poslite-core
helm push poslite-core-1.0.0.tgz oci://atlashelmrepo.azurecr.io/helm

helm package poslite-pam
helm push poslite-pam-1.0.0.tgz oci://atlashelmrepo.azurecr.io/helm

helm package poslite-horustech
helm push poslite-horustech-1.0.0.tgz oci://atlashelmrepo.azurecr.io/helm

helm package poslite-cloudflared-core
helm push poslite-cloudflared-core-1.0.0.tgz oci://atlashelmrepo.azurecr.io/helm

helm package poslite-cloudflared-pam
helm push poslite-cloudflared-pam-1.0.0.tgz oci://atlashelmrepo.azurecr.io/helm

helm package poslite-cloudflared-horustech
helm push poslite-cloudflared-horustech-1.0.0.tgz oci://atlashelmrepo.azurecr.io/helm
```

La versión del `.tgz` sale de `Chart.yaml` (`version: 1.0.0`). Si subes una nueva versión (ej. 1.0.1), actualiza `version` en el `Chart.yaml` del chart antes de empaquetar.

## Verificar que se publicó

```bash
helm show chart oci://atlashelmrepo.azurecr.io/helm/poslite-db --version 1.0.0
helm show chart oci://atlashelmrepo.azurecr.io/helm/poslite-cloudflared-core --version 1.0.0
```

## Después de publicar

1. Si cambiaste la **versión** del chart, actualiza la referencia en los `fleet.yaml` de **atlas-stores** (campo `helm.version`).
2. Fleet sincronizará y desplegará la nueva versión en los clusters que usen ese bundle.
