# Nextcloud

Not deployed. It expects a database `nextcloud` owned by user `nextcloud` on `postgresql.postgresql.svc.cluster.local`,
which does not exist in the cluster yet:

```sql
CREATE DATABASE nextcloud;
CREATE USER nextcloud WITH ENCRYPTED PASSWORD '<password>';
ALTER DATABASE nextcloud OWNER TO nextcloud;
```

`templates/nextcloud-credentials.yaml` is Secret `nextcloud-credentials`, keys `username` and `password` (the
Nextcloud admin) and `postgres-username` and `postgres-password`. Seal it with the command in the
[root README](../../../README.md#secrets).
