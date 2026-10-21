---
name: remove-app
description: Use when an app should be stopped for a while or removed from the cluster for good. deploy false only removes the Argo CD Application and leaves everything running, so this lists what else has to go, in order.
---

# Stop or remove an app

Decide first which one the user wants:

- **Stop for a while, keep the data:** `suspend: true` in the app's `argocd.yaml` (see `kubernetes/README.md`; an app
  that is not a library app also needs `suspendValues` and its own templates reading `.Values.suspend`, as `nextcloud`
  does). The route stays and answers an error. Undo by removing the line.
- **Remove for good:** the steps below. Deleting volumes and disks loses data; get the user's go-ahead for each of
  those steps, and check for a backup first (Velero cannot snapshot the iSCSI disks, see "Backups" in
  `kubernetes/media-server/media-server/README.md`).

The Applications have no finalizer, so removing one never deletes its workloads. An app whose chart has delete hooks
(Argo CD adds `pre-delete-finalizer`/`post-delete-finalizer` to its Application) runs them when the Application goes.

1. **Stop it** with `suspend: true` and let it sync, so nothing writes to the volumes while they are removed.
2. **In git, in one change:** set `deploy: false` (or delete `kubernetes/<group>/<app>/`), remove its hostnames from
   `kubernetes_apps`/`kubernetes_aliases` in `terraform/cloudflare/davydehaas.dev/dns_record.tf`, its OIDC client from
   Authentik (`oidcClients`, `envFrom` and `templates/oidc-client-<slug>.yaml` in `kubernetes/security/authentik`), and
   any Kyverno exemption for its image in `kubernetes/security/kyverno/values.yaml`. Validate with
   `scripts/validate.sh -t`.
3. **After the sync, in the cluster** (the user's go-ahead): delete its namespace, or, when other apps share it, its
   workloads by name. The VerticalPodAutoscalers go with the workloads.
4. **Volumes.** An NFS volume (default StorageClass) is archived on the home server when its claim goes
   (`archiveOnDelete`). An iSCSI PersistentVolume is `Retain`: delete it by hand once its claim is gone.
5. **The iSCSI disk on yggdrasil**, which `lun.sh` cannot remove. Give the user the commands, after
   `sudo targetcli sessions` shows no session on the target: `targetcli /iscsi delete iqn.2026-10.nl.davydehaas:<app>`,
   `targetcli /backstores/fileio delete <app>-config`, `targetcli saveconfig`, then the image
   `/mnt/md0/iscsi/<app>-config.img` and the backups in `/mnt/md0/kubernetes/backups/<app>`. Remove its row from the
   table in that README.
6. **Report** what is gone, what the user still has to run, and anything left (a shared namespace, an archived NFS
   folder).
