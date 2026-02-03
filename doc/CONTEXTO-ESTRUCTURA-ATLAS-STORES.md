# Contexto: Estructura del Repositorio atlas-stores

Archivo de contexto para crear y mantener la estructura del repositorio **atlas-stores**. Usar como referencia al inicializar el repo o al añadir tiendas.

---

## 1. Propósito de atlas-stores

- **atlas-apps**: Contiene los Helm charts (poslite-db, poslite-core, poslite-pam, poslite-horustech, poslite-cloudflared-core, poslite-cloudflared-pam, poslite-cloudflared-horustech y el legacy poslite-cloudflared) y los publica en ACR. Incluye plantillas de tienda en `stores/` para copiar a atlas-stores.
- **atlas-stores**: Contiene **solo configuración**: qué desplegar, en qué clusters y con qué valores (por tienda). Es el repo que Fleet usa para GitOps por tienda.

**Regla:** En atlas-stores **no** hay Helm charts; solo Fleet bundles (y opcionalmente valores por tienda). Los charts se consumen desde `oci://atlashelmrepo.azurecr.io/helm`.

---

## 2. Estructura de directorios recomendada

**Opción A (recomendada): un bundle por tienda, label `store` obligatorio.** Cada tienda tiene su carpeta bajo `fleet/bundles/stores/<id-tienda>/` con un único `fleet.yaml` que despliega db, core (solo tiendas Core), cloudflared-core / cloudflared-pam / cloudflared-horustech y (opcional) pam/horustech, con `clusterSelector`: `atlas: "true"` y `store: "<id-tienda>"`. Así un cambio en una tienda no afecta a otras. Plantillas en **atlas-apps**: `stores/tienda-core-ejemplo`, `stores/tienda-pam-ejemplo`, `stores/tienda-horustech-ejemplo` (copiar la carpeta a `atlas-stores/fleet/bundles/stores/`).

```
atlas-stores/
├── README.md
├── .gitignore
│
├── fleet/
│   └── bundles/
│       └── stores/                    # Un bundle por tienda (store obligatorio)
│           ├── gasparhernandez/
│           │   └── fleet.yaml         # clusterSelector: atlas + store: gasparhernandez
│           ├── tienda-core/
│           │   └── fleet.yaml
│           └── tienda-horustech/
│               └── fleet.yaml
│
└── stores/                            # Valores por tienda (opcional, documentación/overlays)
    └── ejemplo-tienda/
        ├── values-db.yaml
        ├── values-core.yaml
        └── ...
```

---

## 3. Convenciones de nombres

| Elemento        | Convención        | Ejemplo                    |
|-----------------|-------------------|----------------------------|
| Repo            | `atlas-stores`    | —                          |
| Bundle (Fleet)  | Por chart o tienda | `db`, `core`, `stores-ejemplo` |
| Namespace       | `poslite`         | Igual que en atlas-apps    |
| Helm repo       | OCI ACR           | `oci://atlashelmrepo.azurecr.io/helm` |
| Chart version   | Fija en fleet.yaml| `1.0.0` (actualizar al publicar en ACR) |

---

## 4. Labels de clusters (Fleet)

Cada cluster RKE2 debe tener labels para que Fleet aplique el bundle correcto.

**Común:**
- `atlas: "true"` — cluster gestionado por Atlas.

**Por tipo de PosLite (si aplica):**
- `poslite: horustech` — solo bundles horustech.
- `poslite: pam` — solo bundles pam.

**Por tienda:**
- `store: <id-tienda>` — con la **opción A** (un bundle por tienda) es **obligatorio**: cada cluster debe tener `store` para recibir su bundle; sin él no se despliega nada en ese cluster.

Ejemplo de `clusterSelector` con store obligatorio (opción A):

```yaml
clusterSelector:
  matchLabels:
    atlas: "true"
    store: "gasparhernandez"
```

---

## 5. Contenido de `fleet/bundles/<chart>/fleet.yaml`

Un directorio por chart (db, core, cloudflared, pam, horustech). Cada `fleet.yaml` define un único chart y sus valores. Ejemplo **db**:

```yaml
defaultNamespace: poslite
targetCustomizations:
- name: db
  clusterSelector:
    matchLabels:
      atlas: "true"
  helm:
    chart: poslite-db
    repo: oci://atlashelmrepo.azurecr.io/helm
    version: 1.0.0
    values:
      postgresql:
        password: ""   # Usar secret externo o SOPS en producción
        timezone: "America/Panama"
        database: poslite
        user: sa
      persistence:
        enabled: true
        storageClass: local-path
        size: 20Gi
        accessMode: ReadWriteOnce
      pgadmin:
        enabled: true
        defaultPassword: "admin"
```

Ejemplo **core**:

```yaml
defaultNamespace: poslite
targetCustomizations:
- name: core
  clusterSelector:
    matchLabels:
      atlas: "true"
  helm:
    chart: poslite-core
    repo: oci://atlashelmrepo.azurecr.io/helm
    version: 1.0.0
    values:
      portal:
        enabled: true
      webapi:
        enabled: true
      workers:
        price:
          enabled: true
        shift:
          enabled: true
        errorReports:
          enabled: true
        ierp:
          enabled: true
```

Ejemplo **cloudflared-core** (tiendas solo-Core):

```yaml
defaultNamespace: poslite
targetCustomizations:
- name: cloudflared-core
  clusterSelector:
    matchLabels:
      atlas: "true"
      store: "mi-tienda-core"
  helm:
    chart: poslite-cloudflared-core
    repo: oci://atlashelmrepo.azurecr.io/helm
    version: 1.0.0
    values:
      replicas: 1
      hostNetwork: true
      config:
        ingress:
          - hostname: mi-tienda-core-10014.asptienda.com
            service: http://localhost:10014
          # ... resto de hostnames Core + BD (5050, 5432)
```

Para PAM usar chart `poslite-cloudflared-pam`; para Horustech, `poslite-cloudflared-horustech`. El chart legacy `poslite-cloudflared` (todos los puertos) existe pero se prefiere el específico por stack.

---

## 6. Bundles por tipo de tienda (horustech / pam)

Para clusters que solo llevan horustech o pam, usar el label `poslite: horustech` o `poslite: pam` en el cluster y el bundle correspondiente.

Ejemplo `fleet/bundles/horustech/fleet.yaml`:

```yaml
defaultNamespace: poslite
targetCustomizations:
- name: horustech
  clusterSelector:
    matchLabels:
      atlas: "true"
      poslite: horustech
  helm:
    chart: poslite-horustech
    repo: oci://atlashelmrepo.azurecr.io/helm
    version: 1.0.0
    values:
      guardApi:
        enabled: true
      portal:
        enabled: true
      webapi:
        enabled: true
      # ... resto de values
```

---

## 7. Archivos opcionales por tienda en `stores/<tienda>/`

Sirven para documentar o para generar overlays; Fleet no los usa directamente si solo lee `fleet/bundles/`.

- **values-common.yaml**: Valores comunes (entorno, región, etc.).
- **values-db.yaml**: Overrides para poslite-db.
- **values-core.yaml**: Overrides para poslite-core.
- **README.md**: Descripción de la tienda y cómo usar los values.

---

## 8. Checklist al crear atlas-stores

- [ ] Repositorio Git creado (ej. `atlas-stores` en GitHub/GitLab).
- [ ] Estructura por tienda en `fleet/bundles/stores/<id-tienda>/fleet.yaml` (opción A) o por chart en `fleet/bundles/<db|core|cloudflared-core|cloudflared-pam|cloudflared-horustech|pam|horustech>/`.
- [ ] Cada `fleet.yaml` usa `repo: oci://atlashelmrepo.azurecr.io/helm` y `version` correcta.
- [ ] Ningún `helm.chart` apunta a Git; solo a charts en ACR.
- [ ] Repo registrado en Rancher Fleet (Fleet > Git Repos).
- [ ] Clusters con label `atlas: "true"` (y `poslite: horustech` o `poslite: pam` si aplica).
- [ ] Secretos: no commitear contraseñas; usar SOPS, Sealed Secrets o External Secrets y referencias en `values`.

---

## 9. Relación con atlas-apps

| Acción                    | Dónde se hace      |
|---------------------------|--------------------|
| Cambiar templates Helm   | atlas-apps (charts/) |
| Publicar nueva versión   | atlas-apps (CI/CD → ACR) |
| Cambiar qué se despliega | atlas-stores (fleet/bundles/) |
| Cambiar valores por tienda | atlas-stores (values en fleet.yaml o stores/) |

---

## 10. Ejemplo mínimo para empezar

Estructura mínima por tipo de chart (sin grupos de despliegue):

```
atlas-stores/
├── README.md
└── fleet/
    └── bundles/
        └── stores/
            ├── tienda-core-ejemplo/
            │   └── fleet.yaml   # db + core + cloudflared-core
            ├── tienda-pam-ejemplo/
            │   └── fleet.yaml   # db + cloudflared-pam + pam
            └── tienda-horustech-ejemplo/
                └── fleet.yaml   # db + cloudflared-horustech + horustech
```

Cada `fleet.yaml` de tienda incluye varios `targetCustomizations` (db, core o pam/horustech, cloudflared-xxx) con `clusterSelector.matchLabels.atlas: "true"` y `store: "<id-tienda>"`. Las plantillas están en **atlas-apps/stores/**.

Este documento sirve como **archivo de contexto** para crear y mantener la estructura del repo atlas-stores de forma consistente con atlas-apps y Fleet.
