FROM debian:trixie-20261005-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git jq openssh-client xz-utils && rm -rf /var/lib/apt/lists/*

# Trusting the workspace's mise.toml installs bumped versions on first use
COPY --from=jdxcode/mise:2026.11.5 /usr/local/bin/mise /usr/local/bin/mise
ENV MISE_DATA_DIR=/opt/mise \
    MISE_TRUSTED_CONFIG_PATHS=/workspace:/workspaces \
    PATH="/opt/mise/shims:${PATH}"
COPY mise.toml /etc/mise/config.toml
RUN mise install

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:${PATH}" \
    CLAUDE_CONFIG_DIR=/root/.claude
