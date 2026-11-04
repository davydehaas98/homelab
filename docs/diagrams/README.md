# Diagrams

Mermaid sources (`*.mmd`), rendered to PNGs with a white background so they stay readable in dark mode, and shown in the
[README](../../README.md#diagrams). After changing a `.mmd` file, render it from the repository root:

```shell
for d in architecture backup-flow deploy-flow login-flow media-stack request-flow; do
  podman run --rm -v "$PWD/docs/diagrams:/data" ghcr.io/mermaid-js/mermaid-cli/mermaid-cli \
    -p /data/puppeteer.json -i /data/$d.mmd -o /data/$d.png -b white -s 2
done
```
