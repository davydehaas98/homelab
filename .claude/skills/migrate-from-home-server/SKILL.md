---
name: migrate-from-home-server
description: Use when moving an app from the home server's Docker Compose stack (github.com/davydehaas98/home-server) to this cluster. Reads the old compose, config and Traefik labels, decides what to carry over, and builds on add-app.
---

# Migrate an app from home-server

The old setup is in the GitHub repo `davydehaas98/home-server` (public, branch `main`), under `home-stack/`:
`compose.<app>.yaml` and `config/<app>/`. Read it from GitHub, not from a local clone, which may be stale. List files
with `curl -s https://api.github.com/repos/davydehaas98/home-server/git/trees/main?recursive=1`, and read one from
`https://raw.githubusercontent.com/davydehaas98/home-server/main/<path>`. Then build the new app with the `add-app`
skill. This skill is the part `add-app` does not cover: what to carry over
and what to leave behind.

1. **Read the old setup.** The compose file (image, port, user, volumes, environment, healthcheck, resource limits),
   the Traefik labels (hostnames, middleware), and the config folder. Also search the repo for other users of it
   (the tree listing above, or GitHub code search), including the DNS in `_terraform/`.
2. **Translate**, one old field to one new value:
   - image and tag: keep the version, but check it publishes `linux/arm64`; the registry may change;
   - port and healthcheck: `port` and `probe`;
   - `user`, `PUID`/`PGID`: `podSecurityContext`, `env`;
   - limits and reservations: `resources`, not 1:1 (the nodes are small);
   - `privileged`, host networking, devices: do not copy; ask what the app really needs;
   - Traefik hosts: `route.hostnames`, extra hosts as `route.aliases`, and the `.dev` DNS record
     (see `add-app` step 5). Hostnames change from `.nl` to `.dev`, update any `external_url`;
   - `chain-no-auth` means its own login or none; protected means `add-oidc-client`.
3. **Config.** Put static config in a `config/` folder of the app chart with `configFiles[].glob`, one file per
   concern, as `home-assistant` does. Leave out what is tied to the old instance: file logging, websockets nobody
   uses, ids that belong to the old database (such as `device_id`), and anything that needs a service not yet moved.
   Say what you left out in a comment at the top of `values.yaml`.
4. **Secrets** (`secrets.yaml`, password files, tokens): use the `seal-secret` skill; do not copy values.
5. **Data.** For SQLite, a database or state in `/config`, use `add-iscsi-disk` and copy from the old folder on
   yggdrasil (`~/home-server/<app>/`). The data is not in the repo, only the config. Otherwise the default volume.
6. **Cutover**, in this order, with the user:
   1. the new app is deployed and healthy while the old one still runs (different hostname, no shared ports);
   2. stop the old container, copy the data, start the new app;
   3. repoint clients (other apps, devices) to the new address;
   4. remove the compose file, config and DNS from `home-server`, or the next deploy starts it again. That is the
      user's clone and commit; tell them which files, do not edit it unasked.

   Never stop the old container without the user's go-ahead.
7. **Do not commit.** List the files changed here, and the ones to remove in `home-server`.
