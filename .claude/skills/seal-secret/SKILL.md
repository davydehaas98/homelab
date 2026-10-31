---
name: seal-secret
description: Use when a Secret has to be added or changed in the cluster (a password, token, credentials file). Seals it as a SealedSecret without writing or printing the plaintext.
---

# Seal a secret

Never commit plaintext, never print a value, never write it to a file. The rules are in the "Secrets" section of
`AGENTS.md`, the usage in the header of `scripts/seal-secret.sh`; follow those, not a copy of them.

1. **Ask the user for the value, or have them run the script.** You do not have the value, and must not read it from
   `talos/gen/`, `talos/talosconfig`, a `.env` or the live cluster to put it in the output. Give the user the command
   of `scripts/seal-secret.sh` (usage in its header) and have them run it in their own terminal, so the value is not in
   the conversation.

   Always run it in the dev container (`.devcontainer/README.md`), from the repo root, with `~/.kube` mounted.
2. **Name and namespace are part of the seal.** A SealedSecret only decrypts under the name and namespace it was made
   for. Use the namespace of the app (`namespace:` in the app's `argocd.yaml`, else the app name).
3. **The script writes `kubernetes/<group>/<app>/templates/<name>.yaml`**, next to the manifests that use it.
4. **Adding a key to an existing Secret:** a SealedSecret cannot be edited. Use `-m`, which keeps the live Secret's
   keys and re-seals the whole Secret.
5. **A file as a secret** (a password file, a `secrets.yaml`): use `--from-file=<key>=<path>` and mount it with
   `configFiles[].secret` and `keys`, see `kubernetes/_library/app/README.md`.
6. **Commit the sealed file in the same change as the thing that needs it.** A route policy or pod that references a
   Secret that is not there yet breaks.
7. **Check:** the file has `kind: SealedSecret`, `encryptedData`, and no plaintext. `grep -n 'stringData\|data:'` on
   it must not match a real value.
