# ntfy

Push notifications at <https://ntfy.davydehaas.dev>, to the ntfy phone app. Access is denied unless a user or token
allows it. Users, their access and tokens live in `user.db` on the volume, made with the CLI in the pod from the dev
container:

```shell
kubectl -n ntfy exec -it ntfy-0 -- ntfy user add --role=admin <user>
kubectl -n ntfy exec -it ntfy-0 -- ntfy token add <user>
```

An admin reads and publishes every topic. A publisher such as Alertmanager or Home Assistant gets its own user with
`ntfy access <user> <topic> write-only` and a token, sealed into the publisher's app.
