# Media server

The `media` claim is a `local` volume on the media disk of `midgard-0` (`/var/mnt/media`), and the `backups` claim is the
static ZFS volume `media-server-backups` on `tank`, shared by the apps for their own backups. Both are in the
`media-server` namespace. Each app has its own ZFS volume for its config, see
[`storage/zfs-localpv`](../../storage/zfs-localpv/README.md), which also covers how they are backed up.

On the disk, `data/series`, `data/movies`, `data/music` and `data/books` each hold a `library` and a `downloads` folder.
Sonarr, Radarr, Lidarr and LazyLibrarian mount only their own of these at the same path under `/data`, so an import moves
the file instead of copying it, and they can't see each other's media. SABnzbd mounts all of `data` at `/data` for the same reason. Its
folders `/data/downloads/incomplete` and `/data/downloads/complete` and the `downloads` folder per category are in
its config, not in Terraform. Bazarr uses the paths of the `*arr` apps, and Plex and Jellyfin mount each `library`.

The media disk has no redundancy until a second 16T disk gets a pool, the media is copied over, and this disk is wiped
and attached as its mirror (`zpool attach`).
