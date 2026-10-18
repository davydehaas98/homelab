# Dev container

A Debian image with the cluster CLIs from [`mise.toml`](../mise.toml) and Claude Code. It mounts
`~/.kube` and `~/.talos` from the host. A version Renovate bumps in `mise.toml` installs on first
use, without a rebuild.

## Open it

In VS Code with Podman, set `dev.containers.dockerPath` to `podman` and
`dev.containers.mountWaylandSocket` to `false`. Don't let VS Code install Docker in WSL.

On Windows, VS Code can't find the Podman connection (`Cannot connect to Podman`). Name it in a user
environment variable and restart VS Code:

```powershell
[Environment]::SetEnvironmentVariable('CONTAINER_CONNECTION', 'podman-machine-default', 'User')
```

Use the name, not the URI in `CONTAINER_HOST`: `podman machine init` picks a random SSH port, so a
URI goes stale when the machine is recreated, while the name is looked up in
`podman system connection list` every time.

Without VS Code:

```shell
podman build -t homelab-dev -f .devcontainer/Dockerfile .
podman run --rm -it -v "$PWD":/workspace -v ~/.kube:/root/.kube -v ~/.talos:/root/.talos \
  -v homelab-claude-config:/root/.claude -w /workspace localhost/homelab-dev sh
```

## Claude Code

Run `claude`; its login is kept in the `homelab-claude-config` volume. `.claude/settings.json`
blocks `git commit` and `git push`, so changes stay uncommitted for review.

## Git signing

1Password's SSH agent serves one Ed25519 key that authenticates to GitHub and signs commits. VS Code
forwards the agent and copies `~/.gitconfig`, so signing works in the container (reopen it after
changing `~/.gitconfig`). RSA keys can't sign through the forwarded agent.

On a new machine, enable 1Password's SSH agent (Settings > Developer). On Windows, also free its
pipe from the built-in agent (administrator PowerShell), then restart 1Password:

```powershell
C:\Windows\System32\OpenSSH\ssh-add.exe -D
Stop-Service ssh-agent; Set-Service ssh-agent -StartupType Disabled
```

Check with `ssh-add -l` and `ssh -T git@github.com`. `communication with agent failed` means the
1Password prompt was declined or timed out.
