# app library chart

Shared templates for a single-container app: a StatefulSet and a Service, plus an optional volume,
`HTTPRoute` and OIDC `SecurityPolicy`. An app chart only sets values.

## Using it

1. Add the library as a dependency in the app's `Chart.yaml`:

   ```yaml
   apiVersion: v2
   name: <app>
   version: 1.0.0

   dependencies:
     - name: app
       version: 1.0.0
       repository: file://../../_library/app
   ```

2. Add `templates/app.yaml` containing only `{{ include "app.resources" . }}`.
3. Set the values below in the app's `values.yaml`.

Run `helm dependency update` on the app chart before rendering it locally; Argo CD builds the
`file://` dependency itself.

## Values

| Key | Default | Description |
|-----|---------|-------------|
| `image.registry`, `image.repository`, `image.tag` | | Container image. |
| `port` | | Port the app listens on, used by the container, Service and route. |
| `replicas` | `1` | `0` stops the app. |
| `env` | | Environment variables as a map. `TZ` is always set (`Europe/Amsterdam`). |
| `podSecurityContext`, `securityContext`, `resources` | `{}` | Passed to the pod and the container. |
| `probe` | `httpGet` on `/` | Liveness and readiness probe; the port is named `http`. |
| `persistence` | none | The app's volume, a claim named `<app>-config`. Leave it out for a stateless app. |
| `persistence.size` | | Size of the volume. |
| `persistence.mountPath` | `/config` | Where the volume is mounted. |
| `persistence.storageClass` | default class | StorageClass of the claim. |
| `persistence.iscsi.targetPortal`, `.iqn`, `.lun` | | Use a static iSCSI volume instead of a StorageClass. Only one pod may mount it. |
| `persistence.labels` | | Extra labels of the claim. |
| `media.claimName`, `media.mounts` | none | Mount `subPath`s of an existing claim, as a list of `mountPath` + `subPath`. |
| `backups.claimName`, `backups.subPath`, `backups.mountPath` | none, none, `/config/Backups` | Mount a `subPath` of an existing claim for the app's own backups, outside the `/config` volume. |
| `route.enabled`, `route.hostnames`, `route.parentRefs` | off | `HTTPRoute` to the app. Also takes `annotations`, `labels`, `filters`, `matches` and `additionalRules`. |
| `route.aliases` | none | Extra hostnames that redirect (301) to the first hostname. A separate route, so the login keeps working. They need a DNS record too. |
| `oidc.enabled` | off | OIDC login on the route with an Envoy Gateway `SecurityPolicy`. Needs `route.enabled`. |
| `oidc.slug` | chart name | Application slug at the identity provider. |
| `oidc.secretName` | `<app>-oidc-credentials` | Secret with the `client-id` and `client-secret`. |
