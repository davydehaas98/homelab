### values.yaml
|Name|Type|Description|
|---|---|---|
|***deploy***|boolean|If the application should be deployed.|
|***autoSync***|boolean|Defaults to `true`, the application syncs automatically. Set `false` to move it to the `no-sync` project, which is only synced by hand.|
|***ignoreDifferences***|array|What differences should be ignored.|
|***namespace***|string|If the namespace should be overwritten, otherwise it will be application name in kebab case.|
|***serverSideApply***|boolean|If the configuration should be applied with the flag `--server-side` (`kubectl apply --server-side`)|
