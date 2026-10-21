# Apps

Each app is a chart in `kubernetes/<group>/<app>`. The ApplicationSet `yggdrasil`
(`core/argocd/templates/applicationset.yaml`) makes one Argo CD Application per `argocd.yaml` in such a directory
with `deploy: true`. A new group also needs its path in the generator of the ApplicationSet.

Keys of `argocd.yaml`:

| Key | Type | Description |
|---|---|---|
| `deploy` | boolean | Deploy the app. `false`, or no file, removes the Application but leaves its workloads, volumes and databases running; the Applications have no finalizer. |
| `autoSync` | boolean | Default `true`. `false` turns off automated sync, so the app is synced by hand only. |
| `namespace` | string | Default: the app name. |
| `ignoreDifferences` | array | Passed to the Application. |
| `serverSideApply` | boolean | Apply server-side, with the `ServerSideDiff` annotation. |
| `valueFiles` | array | Value files passed to Helm as user values. Set `[values.yaml]` when the app's values remove a subchart default with `null`, which Helm 4 ignores in a chart's own values. |
