# Configurar publicación de Helm charts a ACR

El workflow **Publish Helm charts to ACR** empaqueta y publica los charts de PosLite en Azure Container Registry (OCI). Fleet en atlas-stores consume estos charts desde `oci://atlashelmrepo.azurecr.io/helm`.

## Cuándo se ejecuta

- **Automático:** al hacer push a `main` o `master` cuando cambian archivos en `charts/`.
- **Manual:** en GitHub → **Actions** → **Publish Helm charts to ACR** → **Run workflow**.

## Secrets necesarios

Configura estos secrets en el repositorio:

**GitHub → Settings → Secrets and variables → Actions → New repository secret**

| Secret           | Descripción                                      | Ejemplo                    |
|------------------|--------------------------------------------------|----------------------------|
| `ACR_USERNAME`   | Usuario del Azure Container Registry            | Nombre del recurso ACR     |
| `ACR_PASSWORD`   | Contraseña o token de acceso al ACR              | Contraseña de Admin / SP   |

### Cómo obtener usuario y contraseña (Azure)

1. En Azure Portal, abre el recurso **Container registry** (p. ej. `atlashelmrepo`).
2. **Settings** → **Access keys**.
3. Activa **Admin user** si quieres usar usuario/contraseña.
4. Copia **Login server** (ej. `atlashelmrepo.azurecr.io`), **Username** y **Password**.
5. En GitHub, crea los secrets:
   - `ACR_USERNAME` = Username del ACR.
   - `ACR_PASSWORD` = Password del ACR.

Si usas **Service Principal**, el nombre de usuario es el Application (client) ID y la contraseña el client secret; el registry sigue siendo el mismo.

## Registry por defecto

El workflow usa el registry **atlashelmrepo.azurecr.io**. Si tu ACR tiene otro nombre, edita en `publish-charts.yml` la línea:

```yaml
env:
  ACR_REGISTRY: atlashelmrepo.azurecr.io
```

y pon tu login server (sin `https://`).

## Charts que se publican

Cada ejecución empaqueta y sube estos charts (si existen en `charts/`):

- poslite-db
- poslite-core
- poslite-pam
- poslite-horustech
- poslite-cloudflared-core
- poslite-cloudflared-pam
- poslite-cloudflared-horustech

La versión del `.tgz` se toma de `version` en el `Chart.yaml` de cada chart (p. ej. `1.0.0`).

## Comprobar que funcionó

1. En la pestaña **Actions**, abre la última ejecución del workflow y revisa que el job **publish** termine en verde.
2. Desde tu máquina (con Helm y login al ACR):

   ```bash
   helm show chart oci://atlashelmrepo.azurecr.io/helm/poslite-db --version 1.0.0
   ```

## Solución de problemas

- **Error de login:** comprueba que `ACR_USERNAME` y `ACR_PASSWORD` son correctos y que el usuario tiene permiso para push (p. ej. rol *AcrPush* o Admin user activado).
- **Chart no encontrado:** asegúrate de que la carpeta del chart existe en `charts/` con el nombre exacto (p. ej. `poslite-db`).
- **Versión ya existe:** en OCI, si subes la misma versión suele sobrescribirse; si quieres una nueva, incrementa `version` en el `Chart.yaml` del chart antes de volver a ejecutar el workflow.
