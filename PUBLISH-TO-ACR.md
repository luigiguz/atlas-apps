# Guía: Publicar Helm Charts en Azure Container Registry (ACR)

## Prerrequisitos

1. **Azure CLI instalado**
   ```bash
   # Verificar instalación
   az --version
   
   # Si no está instalado:
   # Windows: https://aka.ms/installazurecliwindows
   # Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   # macOS: brew install azure-cli
   ```

2. **Helm 3.8+ instalado**
   ```bash
   # Verificar versión (debe ser 3.8+)
   helm version
   
   # Si no está instalado:
   # Windows: choco install kubernetes-helm
   # Linux: https://helm.sh/docs/intro/install/
   # macOS: brew install helm
   ```

3. **Acceso a ACR `aspposlite`**
   - Permisos: `AcrPush` o `Owner` en el ACR
   - Login configurado

---

## Paso 1: Login a Azure y ACR

```bash
# 1. Login a Azure
az login

# 2. Seleccionar suscripción (si tienes múltiples)
az account set --subscription "TU-SUBSCRIPTION-ID"

# 3. Login a ACR
az acr login --name aspposlite

# 4. Verificar que el login funcionó
az acr repository list --name aspposlite --output table
```

---

## Paso 2: Verificar Versiones de Charts

Antes de publicar, verifica las versiones en los `Chart.yaml`:

```bash
# Verificar versiones actuales
cat charts/poslite-db/Chart.yaml | grep version
cat charts/poslite-core/Chart.yaml | grep version
cat charts/poslite-pam/Chart.yaml | grep version
cat charts/poslite-horustech/Chart.yaml | grep version
cat charts/poslite-cloudflared/Chart.yaml | grep version
```

**IMPORTANTE:** Asegúrate de que las versiones en `Chart.yaml` coincidan con las versiones en los `fleet.yaml` (actualmente `1.0.0`).

---

## Paso 3: Publicar Charts Individualmente

### Opción A: Publicar uno por uno (Recomendado para primera vez)

```bash
# Navegar a la raíz del repositorio
cd atlas-apps

# 1. Publicar poslite-db
helm package charts/poslite-db
helm push poslite-db-1.0.0.tgz oci://aspposlite.azurecr.io/helm

# 2. Publicar poslite-core
helm package charts/poslite-core
helm push poslite-core-1.0.0.tgz oci://aspposlite.azurecr.io/helm

# 3. Publicar poslite-pam
helm package charts/poslite-pam
helm push poslite-pam-1.0.0.tgz oci://aspposlite.azurecr.io/helm

# 4. Publicar poslite-horustech
helm package charts/poslite-horustech
helm push poslite-horustech-1.0.0.tgz oci://aspposlite.azurecr.io/helm

# 5. Publicar poslite-cloudflared
helm package charts/poslite-cloudflared
helm push poslite-cloudflared-1.0.0.tgz oci://aspposlite.azurecr.io/helm

# Limpiar archivos .tgz generados
rm *.tgz
```

### Opción B: Script para publicar todos

Crea un script `publish-charts.sh`:

```bash
#!/bin/bash

ACR_NAME="aspposlite"
ACR_REPO="oci://${ACR_NAME}.azurecr.io/helm"

# Login a ACR
az acr login --name ${ACR_NAME}

# Lista de charts
CHARTS=("poslite-db" "poslite-core" "poslite-pam" "poslite-horustech" "poslite-cloudflared")

# Publicar cada chart
for chart in "${CHARTS[@]}"; do
    echo "📦 Empaquetando ${chart}..."
    helm package charts/${chart}
    
    # Obtener versión del Chart.yaml
    VERSION=$(grep "^version:" charts/${chart}/Chart.yaml | awk '{print $2}')
    
    echo "🚀 Publicando ${chart} versión ${VERSION} a ACR..."
    helm push ${chart}-${VERSION}.tgz ${ACR_REPO}
    
    echo "✅ ${chart} publicado exitosamente"
    echo ""
done

# Limpiar archivos .tgz
echo "🧹 Limpiando archivos temporales..."
rm *.tgz

echo "✨ Todos los charts han sido publicados!"
```

**Ejecutar el script:**
```bash
chmod +x publish-charts.sh
./publish-charts.sh
```

### Opción C: PowerShell Script (Windows)

Crea `publish-charts.ps1`:

```powershell
$ACR_NAME = "aspposlite"
$ACR_REPO = "oci://${ACR_NAME}.azurecr.io/helm"

# Login a ACR
az acr login --name $ACR_NAME

# Lista de charts
$CHARTS = @("poslite-db", "poslite-core", "poslite-pam", "poslite-horustech", "poslite-cloudflared")

# Publicar cada chart
foreach ($chart in $CHARTS) {
    Write-Host "📦 Empaquetando $chart..." -ForegroundColor Cyan
    
    helm package "charts\$chart"
    
    # Obtener versión del Chart.yaml
    $versionLine = Select-String -Path "charts\$chart\Chart.yaml" -Pattern "^version:"
    $VERSION = ($versionLine -split '\s+')[1]
    
    Write-Host "🚀 Publicando $chart versión $VERSION a ACR..." -ForegroundColor Yellow
    helm push "${chart}-${VERSION}.tgz" $ACR_REPO
    
    Write-Host "✅ $chart publicado exitosamente" -ForegroundColor Green
    Write-Host ""
}

# Limpiar archivos .tgz
Write-Host "🧹 Limpiando archivos temporales..." -ForegroundColor Cyan
Remove-Item *.tgz

Write-Host "✨ Todos los charts han sido publicados!" -ForegroundColor Green
```

**Ejecutar:**
```powershell
.\publish-charts.ps1
```

---

## Paso 4: Verificar Publicación

```bash
# Listar todos los repositorios Helm en ACR
az acr repository list --name aspposlite --output table

# Ver tags (versiones) de un chart específico
az acr repository show-tags --name aspposlite --repository helm/poslite-db --output table

# Verificar que puedes hacer pull del chart
helm pull oci://aspposlite.azurecr.io/helm/poslite-db --version 1.0.0

# Verificar todos los charts
for chart in poslite-db poslite-core poslite-pam poslite-horustech poslite-cloudflared; do
    echo "Verificando $chart..."
    az acr repository show-tags --name aspposlite --repository helm/$chart --output table
done
```

---

## Paso 5: Actualizar Versiones (Para futuras actualizaciones)

Cuando necesites publicar una nueva versión:

1. **Actualizar versión en Chart.yaml:**
   ```bash
   # Editar Chart.yaml y cambiar version: 1.0.0 → 1.0.1
   ```

2. **Publicar nueva versión:**
   ```bash
   helm package charts/poslite-db
   helm push poslite-db-1.0.1.tgz oci://aspposlite.azurecr.io/helm
   ```

3. **Actualizar fleet.yaml:**
   ```yaml
   helm:
     chart: poslite-db
     repo: oci://aspposlite.azurecr.io/helm
     version: 1.0.1  # ← Actualizar aquí
   ```

---

## Troubleshooting

### Error: "failed to authorize: failed to fetch oauth token"

**Solución:**
```bash
# Re-login a ACR
az acr login --name aspposlite

# O verificar credenciales
az acr credential show --name aspposlite
```

### Error: "repository name must be lowercase"

**Solución:** Asegúrate de que el nombre del chart en `Chart.yaml` esté en minúsculas.

### Error: "chart not found" al hacer pull

**Solución:**
1. Verificar que el chart fue publicado:
   ```bash
   az acr repository show-tags --name aspposlite --repository helm/poslite-db
   ```
2. Verificar que la versión coincide exactamente
3. Verificar que el nombre del chart es correcto

### Error: "unauthorized: authentication required"

**Solución:**
1. Verificar permisos en ACR:
   ```bash
   az role assignment list --scope /subscriptions/SUBSCRIPTION-ID/resourceGroups/RG-NAME/providers/Microsoft.ContainerRegistry/registries/aspposlite
   ```
2. Asegurarse de tener rol `AcrPush` o `Owner`

---

## Comandos Rápidos de Referencia

```bash
# Login
az acr login --name aspposlite

# Empaquetar
helm package charts/poslite-db

# Publicar
helm push poslite-db-1.0.0.tgz oci://aspposlite.azurecr.io/helm

# Verificar
az acr repository show-tags --name aspposlite --repository helm/poslite-db

# Pull de prueba
helm pull oci://aspposlite.azurecr.io/helm/poslite-db --version 1.0.0
```

---

## Estructura en ACR

Después de publicar, la estructura en ACR será:

```
aspposlite.azurecr.io/
└── helm/
    ├── poslite-db:1.0.0
    ├── poslite-core:1.0.0
    ├── poslite-pam:1.0.0
    ├── poslite-horustech:1.0.0
    └── poslite-cloudflared:1.0.0
```

---

## Checklist de Publicación

- [ ] Azure CLI instalado y configurado
- [ ] Helm 3.8+ instalado
- [ ] Login a Azure (`az login`)
- [ ] Login a ACR (`az acr login --name aspposlite`)
- [ ] Versiones en Chart.yaml verificadas
- [ ] Todos los charts empaquetados
- [ ] Todos los charts publicados en ACR
- [ ] Verificación exitosa con `az acr repository show-tags`
- [ ] Pull de prueba exitoso con `helm pull`
- [ ] Archivos .tgz limpiados

---

## Notas Importantes

1. **Versiones:** Las versiones en `Chart.yaml` deben coincidir con las versiones en `fleet.yaml`
2. **Nombres:** Los nombres de los charts deben estar en minúsculas
3. **Autenticación:** Los clusters necesitarán credenciales para acceder a ACR
4. **Formato OCI:** ACR usa formato OCI para Helm charts (no ChartMuseum tradicional)

---

**¡Listo!** Una vez publicados los charts, Fleet podrá consumirlos automáticamente desde ACR.
