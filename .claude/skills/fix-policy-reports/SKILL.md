---
name: fix-policy-reports
description: Use when the Kyverno policy reports show failing policies (Pod Security Standards), or before adding an exemption. Reads the reports, separates stale entries from real ones, and fixes in the chart before exempting.
---

# Fix failing policy reports

The Pod Security policies come from `kyverno-policies` in `kubernetes/security/kyverno` (restricted standard). They only
audit (`validationFailureAction: Audit`), so they block nothing; the reports show what to fix. `require-route-login`, in
the chart's own templates, does block.

1. **Read the reports:** `kubectl get policyreport -A -o json`, the failing results per pod (`scope.kind: Pod`) and
   policy. The background scan runs hourly, so a result older than the last change is stale; restarting
   `kyverno-reports-controller` rescans. Reports of excluded namespaces and old ReplicaSets can linger, so judge by
   live pods and result timestamps.
2. **Fix in the chart first:** `seccompProfile: RuntimeDefault`, `allowPrivilegeEscalation: false`, dropped
   capabilities, and `runAsNonRoot` with a user when the image supports it. Check what the image runs as (`id`, `ps`
   in the pod) before choosing.
3. **Test a non-root run** before changing a live app: a throwaway namespace, the same image, the restricted security
   context, `emptyDir` instead of the real volumes, auto-sync off for anything Argo CD creates, and an explicit
   namespace on every manifest. Delete it afterwards. Images whose init starts as root and drops privileges (s6, as
   linuxserver and Home Assistant use) do not run as non-root.
4. **Exempt only what cannot be fixed**, as narrowly as possible: in `kubernetes/security/kyverno/values.yaml`,
   `vpolExclude` for whole namespaces of node agents, or `vpolExcludeByPolicy` with a `matchConditions` on the images
   for one policy. A per-policy entry replaces the global excludes, so repeat them in it. Check the rendered policy
   with `kubectl apply --dry-run=server`, which compiles the CEL.
5. **After the sync**, rescan and read the reports again. A resource that became exempt keeps its old failures until its
   PolicyReport is deleted. Report what is fixed, what is exempt and why, and what still fails.
