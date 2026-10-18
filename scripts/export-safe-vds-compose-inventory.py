#!/usr/bin/env python3
"""Safe structural inventory of old Supabase Compose files. Does not export credentials.
Creates a REVIEW-ONLY YAML-like text, not a deployable Compose config.
"""
import re
from pathlib import Path

ROOT=Path("/opt/supabase")
OUT=Path("/opt/backups/supabase-lite/compose-public-inventory.txt")
FILES=("docker-compose.yml","docker-compose.override.yml")
# Only explicitly allowlisted structural fields; never expose lines for env, volumes,
# labels, commands, ports, network aliases, host paths, secrets, URLs, or extensions.
ALLOW=("image","container_name","profiles")
service_header=re.compile(r"^  ([a-zA-Z0-9_-]+):\s*(?:#.*)?$")
field=re.compile(r"^    (image|container_name|profiles):\s*(.*)$")
image_safe=re.compile(r"^[a-zA-Z0-9_./:-]+$")
name_safe=re.compile(r"^[a-zA-Z0-9_.-]+$")
profile_safe=re.compile(r'^\[\s*"[a-zA-Z0-9_-]+"(?:\s*,\s*"[a-zA-Z0-9_-]+")*\s*\]$')
lines=["# STRUCTURAL INVENTORY ONLY. NOT A DEPLOYABLE COMPOSE FILE.","# Deliberately excludes environment, credentials, ports, paths, mounts, etc.",""]
for filename in FILES:
    p=ROOT/filename
    if not p.is_file():
        raise SystemExit(f"Missing {p}; no output written")
    lines.extend((f"# {filename}","services:"))
    current=None
    in_services=False
    for line in p.read_text(encoding="utf-8").splitlines():
        if line=="services:":
            in_services=True
            continue
        if in_services and line and not line[0].isspace() and not line.startswith("#"):
            in_services=False
            current=None
        if not in_services:
            continue
        m=service_header.match(line)
        if m:
            current=m.group(1)
            lines.append(f"  {current}:")
            continue
        m=field.match(line)
        if m and current:
            key,value=m.groups()
            value=value.strip()
            safe=((key=="image" and image_safe.fullmatch(value)) or
                  (key=="container_name" and name_safe.fullmatch(value)) or
                  (key=="profiles" and profile_safe.fullmatch(value)))
            if safe:
                lines.append(f"    {key}: {value}")
            else:
                lines.append(f"    # {key}: <redacted>")
    lines.append("")
OUT.parent.mkdir(mode=0o700,parents=True,exist_ok=True)
OUT.write_text("\n".join(lines)+"\n",encoding="utf-8")
OUT.chmod(0o600)
print(f"Safe structural inventory written to {OUT}")
print("This file is NOT a full backup or deployable Compose.")
