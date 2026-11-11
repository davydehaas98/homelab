FROM debian:13.7-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git jq openssh-client xz-utils && rm -rf /var/lib/apt/lists/*

# Trusting the workspace's mise.toml installs bumped versions on first use
COPY --from=jdxcode/mise:2026.11.5 /usr/local/bin/mise /usr/local/bin/mise
ENV MISE_DATA_DIR=/opt/mise \
    MISE_TRUSTED_CONFIG_PATHS=/workspace:/workspaces \
    PATH="/opt/mise/shims:${PATH}"
COPY mise.toml /etc/mise/config.toml
RUN mise install

ENV CLAUDE_CONFIG_DIR=/root/.claude
