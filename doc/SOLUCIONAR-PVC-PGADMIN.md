# Solucionar PVC de pgAdmin Bloqueado

El PVC `atlas-store-groups-pilot-poslite-db-pgadmin-data` está programado para eliminación pero no se elimina completamente.

## Paso 1: Verificar el Estado Actual

```bash
# Ver el estado del PVC
kubectl get pvc -n poslite | grep pgadmin

# Ver detalles del PVC
kubectl describe pvc atlas-store-groups-pilot-poslite-db-pgadmin-data -n poslite

# Ver si hay pods usando el PVC
kubectl get pods -n poslite | grep pgadmin
```

## Paso 2: Eliminar el Pod de pgAdmin Primero

```bash
# Eliminar el deployment de pgAdmin (esto eliminará el pod)
kubectl delete deployment atlas-store-groups-pilot-poslite-db-pgadmin -n poslite

# Esperar a que el pod se elimine
kubectl get pods -n poslite -w
```

## Paso 3: Forzar la Eliminación del PVC

Si el PVC sigue bloqueado después de eliminar el pod:

```bash
# Ver los finalizers del PVC
kubectl get pvc atlas-store-groups-pilot-poslite-db-pgadmin-data -n poslite -o yaml | grep finalizers

# Si tiene finalizers, eliminarlos manualmente
kubectl patch pvc atlas-store-groups-pilot-poslite-db-pgadmin-data -n poslite -p '{"metadata":{"finalizers":null}}'

# O eliminar directamente
kubectl delete pvc atlas-store-groups-pilot-poslite-db-pgadmin-data -n poslite --force --grace-period=0
```

## Paso 4: Verificar el StorageClass

```bash
# Verificar que el StorageClass existe y está funcionando
kubectl get storageclass local-path

# Si no existe, puede ser necesario instalarlo
# Para RKE2 con local-path, generalmente viene preinstalado
```

## Paso 5: Esperar a que Fleet Reconcilie

Después de eliminar el PVC:

```bash
# Ver el estado del bundle en Fleet
# En Rancher UI: Fleet > Bundles > db

# O verificar con kubectl
kubectl get gitrepo -n fleet-default
kubectl get bundle -n fleet-default
```

## Paso 6: Si el Problema Persiste

Si el PVC sigue bloqueado, puedes deshabilitar temporalmente pgAdmin:

1. Editar `fleet/bundles/db/fleet.yaml`
2. Cambiar `pgadmin.enabled: false` temporalmente
3. Hacer commit y push
4. Esperar a que Fleet reconcilie
5. Luego volver a habilitar pgAdmin

O eliminar el PVC manualmente desde el nodo:

```bash
# Conectarse al nodo
ssh root@AtlasPoslitePilot

# Ver los volúmenes persistentes
ls -la /var/lib/rancher/rke2/server/manifests/
# O si usa local-path:
ls -la /opt/local-path-provisioner/

# Eliminar el directorio del volumen si es necesario (¡CUIDADO!)
# Solo si estás seguro de que no hay datos importantes
```

## Solución Rápida (Recomendada)

```bash
# 1. Eliminar deployment de pgAdmin
kubectl delete deployment atlas-store-groups-pilot-poslite-db-pgadmin -n poslite

# 2. Eliminar PVC forzadamente
kubectl delete pvc atlas-store-groups-pilot-poslite-db-pgadmin-data -n poslite --force --grace-period=0

# 3. Verificar que se eliminó
kubectl get pvc -n poslite

# 4. Esperar a que Fleet recree todo
# Fleet debería detectar que falta el PVC y recrearlo
```
