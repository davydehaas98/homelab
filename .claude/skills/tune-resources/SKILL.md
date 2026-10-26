---
name: tune-resources
description: Use when setting or changing CPU and memory requests and limits of apps, or when the cluster's summed limits or requests look too high or too low. Sizes from VPA recommendations and actual use, with the rounding the user wants.
---

# Tune requests and limits

Every workload has a VerticalPodAutoscaler that only recommends (Kyverno generates them, see `kubernetes/core/vpa`):
`kubectl get vpa -A`, and the VPA dashboard in Grafana. Its target and upper bound are only as good as its history;
a young VPA, or an upper bound far above use, is a reason to stay careful.

**Gather** per container: current request and limit, use (`kubectl top pods -A --containers`), VPA target and upper
bound, and OOM kills (`lastState.terminated.reason`). Sum requests and limits against the nodes' allocatable memory.

**Rules:**

- Values are powers of two in Mi or Gi (64Mi, 128Mi, … 1Gi, 2Gi). Round up.
- Request: the VPA target, or the use if higher. Limit: about twice the VPA upper bound. When unsure (databases,
  machine learning, Java, spiky or young apps), go higher.
- Never a limit without a request: the request then equals the limit.
- Lower an existing value only when the gap is big: four times or more above both the use and the VPA value.
- CPU: requests only, the VPA target or the use rounded up to 10m steps below 100m and 50m steps above; not powers
  of two. A target at the VPA floor (about 11m) counts as 10m. The media-server apps also have CPU limits; leave
  those unless the user asks.
- Leave the Talos static pods (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`) alone.

**Where the keys are:** library apps `resources` (`kubernetes/_library/app/README.md`); upstream charts their own keys,
read from the chart's values (sidecars, init containers and exporters often have separate ones); CloudNativePG
`spec.resources` on the `Cluster`; containers made by an operator (Prometheus config-reloader, Envoy proxy and
shutdown-manager in the `EnvoyProxy`) through that operator's settings.

**Check before pushing:** render each changed app (`scripts/render-diff.sh`) and confirm the values landed on the
intended containers. A changed resource restarts its pods; a database restart briefly breaks the apps that use it.

**After the sync:** OOM kills and restarts, and the summed requests and limits again. Report the before and after.
