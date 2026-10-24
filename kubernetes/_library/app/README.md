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
| `protocol` | `TCP` | Protocol of `port`. |
| `service.type`, `service.annotations` | `ClusterIP`, none | Type and annotations of the Service. A `LoadBalancer` gets a LAN address from the Cilium pool (`kubernetes/core/cilium`); `lbipam.cilium.io/ips` fixes it. |
| `kind` | `StatefulSet` | `StatefulSet` stops the old pod before it starts the new one, which a volume that only one pod may mount needs. `Deployment` updates without a gap, for an app without `persistence` (the render fails otherwise). |
| `replicas` | `1` | Number of pods; `0` stops the app. |
| `suspend` | `false` | `true` stops the app (0 pods) and keeps its volume, whatever `replicas` says. The ApplicationSet sets it from `suspend: true` in the app's `argocd.yaml`. |
| `args` | none | Arguments of the container, replacing the `CMD` of the image. |
| `env` | | Environment variables as a map. `TZ` is always set (`Europe/Amsterdam`). A value that is a map becomes `valueFrom`, for one key of a Secret (`secretKeyRef`). |
| `podSecurityContext`, `securityContext`, `resources` | `{}` | Passed to the pod and the container. The pod gets `seccompProfile: RuntimeDefault` and the container `allowPrivilegeEscalation: false` unless the values set them. |
| `nodeSelector` | none | Labels a node must have, for a heavy app that should stay off the control plane nodes. |
| `probe` | `httpGet` on `/` | Liveness and readiness probe; the port is named `http`. |
| `persistence` | none | The app's volume, a claim named `<app>-config`. Leave it out for a stateless app. |
| `persistence.size` | | Size of the volume. |
| `persistence.mountPath` | `/config` | Where the volume is mounted. |
| `persistence.storageClass` | default class | StorageClass of the claim. |
| `persistence.iscsi.targetPortal`, `.iqn`, `.lun` | | Use a static iSCSI volume instead of a StorageClass, mounted by the democratic-csi driver (`kubernetes/storage/democratic-csi`). Give every app a target of its own (`iqn.2026-10.nl.davydehaas:<app>`, `lun: 0`), as a node logs out of a whole target when one pod stops. Only one pod may mount it. |
| `persistence.labels` | | Extra labels of the claim. |
| `persistence.backup` | `false` | Annotate the pod so Velero backs up the volume. |
| `media.claimName`, `media.mounts` | none | Mount `subPath`s of an existing claim, as a list of `mountPath` + `subPath` (+ `readOnly: true`). |
| `envFrom` | none | Environment variables from Secrets or ConfigMaps, a list of `secretRef` or `configMapRef` entries. |
| `configFiles` | none | Files mounted into the app, a list of `name`, `mountPath` and either `files` (a map of file name to content) and/or `glob` (files of the app chart, such as `config/*.yaml`, not recursive), rendered into a ConfigMap, and the pod restarts when it changes, or `secret` (the name of an existing Secret, with `keys` to mount). `defaultMode` sets the permissions of the files. Each file is mounted on its own with a `subPath`, so it can sit in an `emptyDirs` folder that stays writable. |
| `emptyDirs` | none | Scratch volumes, a list of `name`, `mountPath` and optionally `medium: Memory` and `sizeLimit`. Gone when the pod restarts. |
| `backups.claimName`, `backups.subPath`, `backups.mountPath` | none, none, `/config/Backups` | Mount a `subPath` of an existing claim for the app's own backups, outside the `/config` volume. |
| `route.enabled`, `route.hostnames`, `route.parentRefs` | off | `HTTPRoute` to the app. Also takes `annotations`, `labels`, `filters`, `matches` and `additionalRules`. |
| `route.aliases` | none | Extra hostnames that redirect (301) to the first hostname. A separate route, so the login keeps working. They need a DNS record too. |
| `route.auth` | none | Why an app has no login at the gateway, with `oidc.enabled: false`: `native` (the app's own login, such as a mobile app that cannot follow a redirect) or `public`. Set as the annotation `davydehaas.dev/auth` of the route, which the Kyverno policy `require-route-login` checks. The route of a login is annotated `gateway`, an alias route `redirect` and a bypass route `bypass`. |
| `oidc.enabled` | on | OIDC login on the route with an Envoy Gateway `SecurityPolicy`. Needs `route.enabled`, and an Authentik client with sealed credentials (the `add-oidc-client` skill): without them the route breaks, which is on purpose. Set `false`, with `route.auth`, to skip it. |
| `oidc.slug` | chart name | Application slug at the identity provider. |
| `oidc.secretName` | `<app>-oidc-credentials` | Secret with the `client-id` and `client-secret`. |
| `oidc.bypassPaths` | none | Paths that skip the login, as a second route without the policy (`<app>-bypass`). For an API that clients call with the app's own API key. |
