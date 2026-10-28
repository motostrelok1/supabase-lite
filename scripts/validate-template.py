#!/usr/bin/env python3
"""Validate repository-safe configuration without printing secrets or connecting to a server."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
template = (ROOT / ".env.example").read_text(encoding="utf-8")
names = re.findall(r"^([A-Z][A-Z0-9_]*)=", template, re.M)
required = ["COMPOSE_PROJECT_NAME", "POSTGRES_PASSWORD", "JWT_SECRET", "ANON_KEY", "SERVICE_ROLE_KEY", "API_PUBLIC_URL", "SITE_URL"]
if len(names) != len(set(names)):
    sys.exit("FAIL: duplicate .env.example variable")
if any(name not in names for name in required):
    sys.exit("FAIL: required configuration variable missing")
if any(path.exists() for path in [ROOT / "compose.yml", ROOT / "docker-compose.yml"]):
    print("INFO: a Compose definition exists; validate with docker compose config --quiet (do not log expanded output)")
else:
    print("INFO: Compose is not supplied yet; repository is NOT installable")
print(f"PASS: {len(names)} placeholder configuration keys checked; no secrets shown")
