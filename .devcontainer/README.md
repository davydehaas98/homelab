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

When `podman` says the connection is refused, run `pwsh .devcontainer/podman-fix.ps1`: it restarts the machine, whose SSH
port can stop listening while it shows as running.

## Desktop app

Without VS Code, the container runs in the background with sshd on `127.0.0.1:2222`, for the Code tab's SSH sessions.
It lets in the public key mounted as `authorized_keys`, which the SSH agent must hold, and keeps its host key and the
logins of Claude Code and `gh` in volumes:

```shell
podman build -t homelab-dev -f .devcontainer/Dockerfile .
podman run -d --name homelab-dev --hostname homelab --restart unless-stopped -p 127.0.0.1:2222:22 \
  -v "$PWD:/workspace" -v "$HOME/.kube:/root/.kube" -v "$HOME/.talos:/root/.talos" \
  -v "$HOME/.ssh/homelab-ssh.pub:/etc/ssh/authorized_keys:ro" -v homelab-dev-ssh:/etc/ssh/keys \
  -v homelab-claude-config:/root/.claude -v homelab-gh-config:/root/.config/gh \
  -v "$HOME/.claude/CLAUDE.md:/root/.claude/CLAUDE.md:ro" -e GRAFANA_MCP_TOKEN -w /workspace localhost/homelab-dev
```

Add the host to `~/.ssh/config` (`HostName 127.0.0.1`, `Port 2222`, `User root`, the key as `IdentityFile`) and its
alias as an SSH connection in the desktop app, with folder `/workspace`. The agent isn't forwarded, so commits made
there are unsigned. A rebuilt image needs `podman rm -f homelab-dev` and the run again.

The container also serves Remote Control as `homelab`, for the Claude app, once `claude` in `/workspace` has trusted
the folder and `claude remote-control` has been enabled there by hand; its log is `/var/log/remote-control.log`.

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
server in the cluster (`kubernetes/monitoring/grafana-mcp`), which needs the `server-token` of its sealed
`grafana-mcp-credentials`. Set it on the host and restart VS Code:

```powershell
[Environment]::SetEnvironmentVariable('GRAFANA_MCP_TOKEN', '<token>', 'User')
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
