# Nextcloud

Not deployed. The official chart, with the pieces it needs next to it:

- `templates/database.yaml`: PostgreSQL run by CloudNativePG (deploy `cloudnative-pg` first), on an iSCSI disk of its own,
  see [the media-server README](../../media-server/media-server/README.md#iscsi-disks). The disk is owned by the postgres user
  (`OWNER=26:26`). CloudNativePG creates the Secret `nextcloud-database-app`, which the chart reads.
- `templates/valkey.yaml`: the cache and file locking, without storage.
- `templates/nextcloud-credentials.yaml`: Secret `nextcloud-credentials`, keys `username` and `password` of the admin.
  Seal it with the command in the [root README](../../../README.md#secrets).

The code and config are on one volume and the files of the users on another, both on NFS. Nextcloud upgrades one major
version at a time, so to bring over an existing install, start with the image tag of that install and upgrade from there.
