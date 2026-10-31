# Media server

The `media` claim is a `local` volume on the media disk of `midgard-0` (`/var/mnt/media`), and the `backups` claim is the
static ZFS volume `media-server-backups` on `tank`, shared by the apps for their own backups. Both are in the
`media-server` namespace. Each app has its own ZFS volume for its config, see
[`storage/zfs-localpv`](../../storage/zfs-localpv/README.md), which also covers how they are backed up.

Sonarr, Radarr and Lidarr mount only their own folder under `downloads/usenet/complete`, so the categories `series`,
`movies` and `audio` in SABnzbd each need that folder as Folder/Path. These settings are in its config, not in Terraform.

The media disk has no redundancy until a second 16T disk gets a pool, the media is copied over, and this disk is wiped
and attached as its mirror (`zpool attach`).
