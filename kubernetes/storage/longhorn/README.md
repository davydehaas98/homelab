# Longhorn

Not deployed: the nodes have no usable data disk. Sealed with the command in the
[root README](../../../README.md#secrets):

- `templates/s3-credentials.yaml`: Secret `s3-credentials`, keys `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and
  `AWS_ENDPOINTS`, for the backup target.
- `templates/oidc-credentials.yaml`: Secret `oidc-credentials`, keys `client-id` and `client-secret` of the Authentik
  client `longhorn`.
