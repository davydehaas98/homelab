# Dev container

Debian with the CLIs from [`mise.toml`](../mise.toml) and Claude Code, mounting `~/.kube` and `~/.talos` from the host.
Versions Renovate bumps install on first use, without a rebuild.

## Podman

In VS Code set `dev.containers.dockerPath` to `podman` and `dev.containers.mountWaylandSocket` to `false`, and don't
let it install Docker in WSL. On Windows, name the Podman connection (not its URI, whose port changes when the
machine is recreated) and restart VS Code:

```powershell
[Environment]::SetEnvironmentVariable('CONTAINER_CONNECTION', 'podman-machine-default', 'User')
```

Without VS Code:

```shell
podman build -t homelab-dev -f .devcontainer/Dockerfile .
podman run --rm -it -v "$PWD":/workspace -v ~/.kube:/root/.kube -v ~/.talos:/root/.talos \
  -v homelab-claude-config:/root/.claude -e GRAFANA_SERVICE_ACCOUNT_TOKEN -w /workspace localhost/homelab-dev sh
```

## Cluster CLIs

`kubectl`, `helm` and `kubeseal` use `~/.kube/config` as it is. `argocd --core` talks to the cluster through the
kubeconfig and looks for its config in the context's namespace, so it fails with `configmap "argocd-cm" not found`
until that is `argocd`. `~/.kube/config` is a bind mount of the host's, so to leave it alone, set the namespace on a
copy:

```shell
cp ~/.kube/config /tmp/kubeconfig && export KUBECONFIG=/tmp/kubeconfig
kubectl config set-context --current --namespace=argocd
argocd app list --core
```

`talosctl` needs `~/.talos`, which the command above mounts.

## Claude Code

Run `claude`; its login is kept in the `homelab-claude-config` volume. `.mcp.json` adds the read-only Grafana MCP
server, which needs a token of a Grafana service account with the Viewer role (Administration > Users and access >
Service accounts). Set it on the host and restart VS Code:

```powershell
[Environment]::SetEnvironmentVariable('GRAFANA_SERVICE_ACCOUNT_TOKEN', '<token>', 'User')
```

## Git signing

1Password's SSH agent serves the Ed25519 key that authenticates to GitHub and signs commits. VS Code forwards the
agent and copies `~/.gitconfig` (reopen the container after changing it). RSA keys can't sign through the forwarded
agent. On a new machine, enable the agent in 1Password (Settings > Developer); on Windows, free its pipe first in an
administrator PowerShell, then restart 1Password:

```powershell
C:\Windows\System32\OpenSSH\ssh-add.exe -D
Stop-Service ssh-agent; Set-Service ssh-agent -StartupType Disabled
```

Check with `ssh-add -l` and `ssh -T git@github.com`.
