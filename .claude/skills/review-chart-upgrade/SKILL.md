---
name: review-chart-upgrade
description: Use when reviewing a Renovate PR or bump of a Helm chart dependency or image that did not automerge (minor or major), or before bumping one by hand. Finds renamed values, changed defaults, CRD changes and delete hooks before the merge deploys it.
---

# Review a chart upgrade

Renovate automerges patch and digest updates of the charts and image tags; the rest waits for a review. A merge to
`main` deploys.

1. **Read the release notes** between the two versions (the chart's changelog or GitHub releases, and the app's for a
   new app version): breaking changes, renamed or removed values, new required values, minimum Kubernetes version.
2. **Check this repo's values** against them: every key the app's `values.yaml` sets under the dependency must still
   exist, with the same meaning. A renamed key is silently ignored.
3. **Render the difference:** on the PR branch, `scripts/render-diff.sh -r origin/main <group>/<app>`. Look for:
   - removed or renamed resources (Argo CD prunes them; a renamed PVC or StatefulSet means new, empty storage);
   - changed selectors or StatefulSet volume templates, which Kubernetes refuses to change in place;
   - CRD changes, and whether the app needs `serverSideApply`;
   - new hooks: Argo CD adds `pre-delete`/`post-delete` finalizers for delete hooks, which run when the Application is
     deleted;
   - changed security contexts, resources or images.
4. **Validate** with `scripts/validate.sh <group>/<app>`.
5. **Report** what changes, what in `values.yaml` must change with it, and the risk. For an app with state, say what a
   rollback would mean (a database migrated by the new version may not run on the old one).
