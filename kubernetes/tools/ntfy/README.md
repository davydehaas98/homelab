# ntfy

Push notifications at <https://ntfy.davydehaas.dev>. Access is denied without a user or token, both kept in `user.db`
on the volume:

```shell
kubectl -n ntfy exec -it ntfy-0 -- ntfy user add --role=admin <user>
kubectl -n ntfy exec -it ntfy-0 -- ntfy token add <user>
```

A publisher gets its own user with `ntfy access <user> <topic> write-only` and a token.
