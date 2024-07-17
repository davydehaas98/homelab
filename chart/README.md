### values.yaml
|Name|Type|Description|
|---|---|---|
|***deploy***|boolean|If the application should be deployed.|
|***autoSync***|boolean|If the application should be auto synced. This means it will automatically update if needed.|
|***ignoreDifferences***|array|What differences should be ignored.|
|***namespace***|string|If the namespace should be overwritten, otherwise it will be application name in kebab case.|
|***serverSideApply***|boolean|If the configuration should be applied with the flag `--server-side` (`kubectl apply --server-side`)|
