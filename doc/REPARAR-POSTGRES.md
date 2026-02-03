# Guía para Reparar PostgreSQL

## Paso 1: Publicar el Chart Actualizado a ACR

```powershell
# Navegar al directorio de charts
cd "C:\Users\luigi\Documents\Apps - Luigi\Luigi\Luis Guzman\Verkku\Atlas\Git\atlas-apps\charts"

# Login a ACR
helm registry login atlashelmrepo.azurecr.io
# Username: atlashelmrepo
# Password: [tu contraseña]

# Empaquetar el chart
helm package poslite-db

# Publicar a ACR
helm push poslite-db-1.0.0.tgz oci://atlashelmrepo.azurecr.io/helm

# Verificar que se publicó
helm show chart oci://atlashelmrepo.azurecr.io/helm/poslite-db --version 1.0.0
```

## Paso 2: Limpiar el PVC y Pod en el Cluster

**IMPORTANTE:** Esto eliminará los datos existentes. Asegúrate de tener un backup si es necesario.

```bash
# Conectarse al cluster (desde el nodo o con kubectl configurado)
# Ejemplo si estás en el nodo:
ssh root@AtlasPoslitePilot

# 1. Eliminar el pod (se recreará automáticamente)
kubectl delete pod atlas-store-groups-pilot-poslite-db-postgres-0 -n poslite

# 2. Eliminar el PVC (esto borra los datos persistentes)
kubectl delete pvc data-atlas-store-groups-pilot-poslite-db-postgres-0 -n poslite

# 3. Esperar a que el StatefulSet recree el pod y PVC
kubectl get pods -n poslite -w

# 4. Verificar que el nuevo pod está iniciando
kubectl get pods -n poslite | grep postgres

# 5. Ver logs del nuevo pod (debe inicializar correctamente)
kubectl logs atlas-store-groups-pilot-poslite-db-postgres-0 -n poslite -f
```

## Paso 3: Verificar que PostgreSQL Funciona

```bash
# Verificar que el pod está Running
kubectl get pods -n poslite | grep postgres

# Verificar que PostgreSQL acepta conexiones
kubectl exec -it atlas-store-groups-pilot-poslite-db-postgres-0 -n poslite -- psql -U sa -d poslite -c "SELECT version();"

# Verificar la configuración
kubectl exec -it atlas-store-groups-pilot-poslite-db-postgres-0 -n poslite -- psql -U sa -d poslite -c "SHOW shared_buffers;"
```

## Paso 4: Aplicar la Configuración Personalizada (Opcional)

Si necesitas aplicar la configuración personalizada (`postgresql.conf`), después de que PostgreSQL se inicialice:

```bash
# El postStart hook debería copiar la configuración automáticamente
# Si no se aplicó, reinicia el pod una vez:
kubectl delete pod atlas-store-groups-pilot-poslite-db-postgres-0 -n poslite

# Esperar a que se reinicie
kubectl get pods -n poslite -w
```

## Notas

- El chart actualizado elimina el initContainer que causaba el problema
- PostgreSQL se inicializará normalmente sin interferencias
- La configuración personalizada se copiará después de la inicialización mediante el hook `postStart`
- Si necesitas que la configuración se aplique desde el inicio, reinicia el pod una vez después de la primera inicialización
