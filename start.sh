#!/bin/bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  set -- hermes gateway
fi

# Create every directory hermes expects and seed a default config.yaml if the
# persistent volume is empty.
mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace

if [ ! -f /data/.hermes/config.yaml ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example /data/.hermes/config.yaml
fi

# Railway Variables are the source of truth. Hermes also reads
# /data/.hermes/.env for runtime credentials/config, so rewrite it from the
# current container environment on every boot.
python3 - <<'PY'
import os
import re
import tempfile

env_path = "/data/.hermes/.env"
env_dir = os.path.dirname(env_path)
name_re = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def quote_dotenv(value: str) -> str:
    value = value.replace("\\", "\\\\")
    value = value.replace("\n", "\\n")
    value = value.replace("\r", "\\r")
    value = value.replace('"', '\\"')
    return f'"{value}"'


fd, tmp_path = tempfile.mkstemp(prefix=".env.", dir=env_dir, text=True)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        os.fchmod(fh.fileno(), 0o600)
        fh.write("# Generated from container environment by /app/start.sh.\n")
        fh.write("# Railway Variables remain the source of truth; this file is overwritten on every boot.\n")
        for key in sorted(os.environ):
            if not name_re.match(key):
                continue
            if key.startswith("RAILWAY_"):
                continue
            fh.write(f"{key}={quote_dotenv(os.environ[key])}\n")
    os.replace(tmp_path, env_path)
except Exception:
    try:
        os.unlink(tmp_path)
    except OSError:
        pass
    raise
PY

# Clear any stale gateway PID file left over from the previous container.
# `hermes gateway` writes /data/.hermes/gateway.pid on start but does not
# remove it on SIGTERM. Since /data is a persistent volume, the file
# survives container restarts and causes every subsequent boot to exit with
# "ERROR gateway.run: PID file race lost to another gateway instance".
# No hermes process can be running at this point (we're pre-exec in a fresh
# container), so removing the file unconditionally is safe.
rm -f /data/.hermes/gateway.pid

exec "$@"
