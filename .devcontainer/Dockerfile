FROM debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git jq openssh-client xz-utils && rm -rf /var/lib/apt/lists/*

# Trusting the workspace's mise.toml installs bumped versions on first use
COPY --from=jdxcode/mise:2026.11.14 /usr/local/bin/mise /usr/local/bin/mise
ENV MISE_DATA_DIR=/opt/mise \
    MISE_TRUSTED_CONFIG_PATHS=/workspace:/workspaces \
    PATH="/opt/mise/shims:${PATH}"
COPY mise.toml /etc/mise/config.toml
RUN mise install

ENV CLAUDE_CONFIG_DIR=/root/.claude

# For the desktop app's SSH sessions; VS Code replaces the command, so it runs only without VS Code
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory /workspace \
    && echo 'export PATH="/opt/mise/shims:${PATH}"' > /etc/profile.d/mise.sh
COPY .devcontainer/sshd.conf /etc/ssh/sshd_config.d/homelab.conf
COPY .devcontainer/sshd.sh /usr/local/bin/sshd.sh
CMD ["sh", "/usr/local/bin/sshd.sh"]
