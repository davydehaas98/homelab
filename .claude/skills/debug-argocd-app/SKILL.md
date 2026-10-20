---
name: debug-argocd-app
description: Use when an app is OutOfSync, Degraded, Progressing for too long, or fails to sync or start. Read-only triage that follows the way this cluster is wired, before anything is changed.
---

# Debug an Argo CD app

Read-only first: `get`, `describe`, `logs`, `events`. Do not sync, delete, restart or edit anything until the cause is
known and the user agrees. The fix goes in git, as `AGENTS.md` says; a merge to `main` is a deployment.

The namespace is the app name unless `namespace:` is set in `chart/values.yaml`. Run the CLIs in the dev container.

1. **Is it deployed at all?** The app needs `deploy: true` under `applications.<group>.<app>` in `chart/values.yaml`
   and a directory `kubernetes/<group>/<app>`. Then `kubectl -n argocd get application <app> -o yaml` and read
   `status.conditions`, `status.sync`, `status.health` and `status.operationState.message`.
2. **Which project?** `autoSync: false` puts it in AppProject `no-sync`: OutOfSync is expected and only a manual sync
   moves it.
3. **Render fails** (`ComparisonError`, `InvalidSpecError`): reproduce with `helm dependency update` and
   `helm template kubernetes/<group>/<app> --api-versions monitoring.coreos.com/v1`. Typical causes are a values key
   that a chart bump renamed, a missing dependency, or a `null` in values that needs `valueFiles: [values.yaml]`.
4. **Sync fails on a missing CRD** (`no matches for kind`): the app depends on another app's CRDs
   (`sealed-secrets`, `envoy-gateway`, `prometheus-crd`). Failed first syncs are not retried. Check that the app
   owning the CRDs is Healthy, then ask the user to sync this one.
5. **Perpetually OutOfSync**: the API server adds defaults. Look at `argocd app diff <app>` or the resource's diff in
   the UI. Fix with `serverSideApply: true` (which adds `ServerSideDiff`) or `ignoreDifferences`, both in
   `chart/values.yaml`.
6. **SealedSecret not decrypting**: `kubectl -n <ns> get sealedsecret` and `describe` it, and
   `kubectl -n kube-system logs deploy/sealed-secrets-controller`. A seal is bound to its name and namespace, so a
   renamed Secret or a changed `namespace:` needs a re-seal (skill `seal-secret`). `no key could decrypt` means the
   controller lacks the key, see "Sealed-secrets keys" in `talos/README.md`.
7. **Healthy sync, broken pod**: `kubectl -n <ns> get pods`, then `describe pod` (events) and
   `logs --previous` for crash loops. Check, in order:
   - `ImagePullBackOff` or `exec format error`: the image has no arm64 build.
   - `Pending` on a PVC: the StorageClass, or an iSCSI disk that is not there (skill `add-iscsi-disk`).
   - A SQLite or database error on NFS: it needs its own iSCSI disk.
   - `FailedMount` on a Secret or ConfigMap: it is missing or in another namespace.
8. **Reachable?** `kubectl -n <ns> get httproute` and check it is `Accepted` and `ResolvedRefs`, with parent Gateway
   `envoy-gateway`, `sectionName: web-https`. Then the DNS record in `terraform/cloudflare/davydehaas.dev/dns_record.tf`.
   A `SecurityPolicy` whose Secret is missing breaks the route (skill `add-oidc-client`).

Report the cause with the evidence (the message or event that shows it), the file that has to change, and what you did
not check. Do not claim a cause that you only inferred.
