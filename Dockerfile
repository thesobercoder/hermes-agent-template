FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Which hermes-agent revision to install. Accepts any git ref the upstream
# repo publishes — a release tag (recommended for reproducibility) or a
# branch name (`main`) for bleeding edge.
#
# To bump: check https://github.com/NousResearch/hermes-agent/releases for the
# newest tag (format `vYYYY.M.D`, e.g. `v2026.4.23`) and update the default
# below. Use `main` only if you accept that every rebuild can pull arbitrary
# new upstream commits.
ARG HERMES_REF=v2026.4.30

ENV BUN_INSTALL=/usr/local/bun
ENV PATH="${BUN_INSTALL}/bin:${PATH}"

# tini = tiny init that we run as PID 1. Without it, hermes's grandchild
# processes (MCP stdio servers, git, bun, browser daemons spawned by tools)
# reparent to PID 1 when their parents exit and pile up as zombies. After
# weeks of uptime that exhausts the kernel's PID table → "fork: cannot
# allocate memory" and the container dies. tini reaps zombies in the
# background and forwards SIGTERM/SIGINT to our entrypoint so Railway's
# stop signal still triggers our graceful shutdown. Standard container init
# (same as Docker's `--init` flag and Kubernetes' pause container).
#
# Python, pip, and uv come from the base image. Node.js, npm, pnpm, and Bun are
# runtime tools the agent can use for generated projects, MCP servers, and
# shell workflows.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl git tini unzip ffmpeg && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g pnpm && \
    npm cache clean --force && \
    curl -fsSL https://bun.sh/install | bash && \
    ln -sf ${BUN_INSTALL}/bin/bun /usr/local/bin/bun && \
    ln -sf ${BUN_INSTALL}/bin/bunx /usr/local/bin/bunx && \
    rm -rf /var/lib/apt/lists/*

# Install hermes-agent, which provides the `hermes` CLI used as the container
# process.
RUN git clone --depth 1 --branch ${HERMES_REF} https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    cd /opt/hermes-agent && \
    uv pip install --system --no-cache -e ".[all]" && \
    rm -rf /opt/hermes-agent/.git /root/.cache/uv

RUN mkdir -p /data/.hermes

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV HOME=/data
ENV HERMES_HOME=/data/.hermes

# tini wraps start.sh so it runs as PID 1's child instead of as PID 1 itself.
# `-g` propagates signals to the whole process group so `docker stop` /
# Railway's SIGTERM cleanly terminates the entire tree.
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/app/start.sh"]
CMD ["hermes", "gateway"]
