# Nextcloud

The official chart, with the pieces it needs next to it:

- `templates/database.yaml`: PostgreSQL run by CloudNativePG (deploy `cloudnative-pg` first), on a ZFS volume of its own.
  CloudNativePG creates the Secret `nextcloud-database-app`, which the chart reads.
- `templates/valkey.yaml`: the cache and file locking, without storage.
- `templates/nextcloud-credentials.yaml`: Secret `nextcloud-credentials`, keys `username` and `password` of the admin.
  Seal it with the command in the [root README](../../../README.md#secrets).

The code and config are on one ZFS volume and the files of the users on another. Nextcloud upgrades one major
version at a time, so to bring over an existing install, start with the image tag of that install and upgrade from there.
