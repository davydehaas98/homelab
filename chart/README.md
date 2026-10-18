# Applications chart

Keys of an app in `values.yaml` (`applications.<group>.<app>`):

| Key | Type | Description |
|---|---|---|
| `deploy` | boolean | Deploy the app. |
| `autoSync` | boolean | Default `true`. `false` moves the app to AppProject `no-sync`, synced by hand only. |
| `namespace` | string | Default: the app name. |
| `ignoreDifferences` | array | Passed to the Application. |
| `serverSideApply` | boolean | Apply server-side, with the `ServerSideDiff` annotation. |
| `valueFiles` | array | Value files passed to Helm as user values. Set `[values.yaml]` when the app's values remove a subchart default with `null`, which Helm 4 ignores in a chart's own values. |
