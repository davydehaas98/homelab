---
name: seal-secret
description: Use when a Secret has to be added or changed in the cluster (a password, token, credentials file). Seals it as a SealedSecret without writing or printing the plaintext.
---

# Seal a secret

Never commit plaintext, never print a value, never write it to a file. The flow is in the "Secrets" section of
`README.md`; follow that, not a copy of it.

1. **Ask the user for the value, or have them run the command.** You do not have the value, and must not read it from
   `talos/gen/`, `talos/talosconfig`, a `.env` or the live cluster to put it in the output. Give the user the exact
   command with `read -rs value` and tell them to run it with `! <command>`, so the output lands in the repo and not
   in the conversation.

   Always run the command in the dev container (`.devcontainer/README.md`), from the repo root, as in `AGENTS.md`.
2. **Name and namespace are part of the seal.** A SealedSecret only decrypts under the name and namespace it was made
   for. Use the namespace of the app (`namespace:` in `chart/values.yaml`, else the app name).
3. **Write to `kubernetes/<group>/<app>/templates/<name>.yaml`**, next to the manifests that use it.
4. **Adding a key to an existing Secret:** a SealedSecret cannot be edited. Read the live Secret's keys (not their
   values in the output), merge the new key into it, and re-seal the whole Secret.
5. **A file as a secret** (a password file, a `secrets.yaml`): use `--from-file=<key>=<path>` and mount it with
   `configFiles[].secret` and `keys`, see `kubernetes/_library/app/README.md`.
6. **Commit the sealed file in the same change as the thing that needs it.** A route policy or pod that references a
   Secret that is not there yet breaks.
7. **Check:** the file has `kind: SealedSecret`, `encryptedData`, and no plaintext. `grep -n 'stringData\|data:'` on
   it must not match a real value.
