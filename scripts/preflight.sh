#!/usr/bin/env bash
# Safe, read-only preflight: does NOT start Docker, generate secrets, or print env values.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Supabase Lite preflight (read-only)"
command -v docker >/dev/null || { echo "FAIL: docker missing"; exit 1; }
docker compose version >/dev/null || { echo "FAIL: compose plugin missing"; exit 1; }
docker info >/dev/null 2>&1 || { echo "FAIL: Docker engine unavailable"; exit 1; }
command -v python3 >/dev/null || { echo "FAIL: python3 missing"; exit 1; }
python3 - <<'PY'
import os, re, shutil, sys
project=os.environ.get("COMPOSE_PROJECT_NAME","")
if project and not re.fullmatch(r"[a-z][a-z0-9_-]{2,40}",project):
    sys.exit("FAIL: COMPOSE_PROJECT_NAME must be a unique lowercase identifier")
disk=shutil.disk_usage(".")
if disk.free<5*1024**3:
    print("WARN: fewer than 5 GiB available (not a capacity certification)")
else: print("OK: >=5 GiB free at repository location")
if os.path.exists(".env"):
    mode=os.stat(".env").st_mode & 0o777
    if mode & 0o077: sys.exit("FAIL: .env permissions expose secrets; use chmod 600 .env")
    text=open(".env",encoding="utf-8").read()
    needed=["POSTGRES_PASSWORD","JWT_SECRET","ANON_KEY","SERVICE_ROLE_KEY","API_PUBLIC_URL","SITE_URL"]
    entries=dict(re.findall(r"^([A-Z][A-Z0-9_]*)=(.*)$",text,re.M))
    missing=[x for x in needed if not entries.get(x)]
    if missing: sys.exit("FAIL: missing environment variable names: "+", ".join(missing))
    if any("REPLACE_WITH" in v or "example.invalid" in v for v in entries.values()):
        sys.exit("FAIL: placeholder values remain; no values shown")
    if len(entries["JWT_SECRET"])<32: sys.exit("FAIL: JWT_SECRET shorter than 32 characters")
    print("OK: .env permissions and required variable presence")
else:
    print("INFO: no .env: copy .env.example and generate unique secrets locally")
print("NOTE: compose.yml not yet shipped; this does NOT certify an installable stack")
PY
echo "Read-only checks complete."
