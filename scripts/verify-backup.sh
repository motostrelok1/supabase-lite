#!/usr/bin/env bash
# Read-only archive inspection. Decrypt only to a private temp dir and verify digests.
set -Eeuo pipefail
umask 077
if [[ $# -ne 2 || "$1" != /* || "$2" != /* ]]; then
  echo "Usage: bash scripts/verify-backup.sh /absolute/archive.tar.age /absolute/age-identity.txt" >&2; exit 2
fi
archive=$1; identity=$2
[[ -f "$archive" && -f "$identity" && ! -L "$archive" && ! -L "$identity" ]] || { echo "Invalid archive/identity" >&2; exit 2; }
for cmd in age tar sha256sum pg_restore python3; do command -v "$cmd" >/dev/null || exit 2; done
temp="$(mktemp -d)"; trap 'rm -rf "$temp"' EXIT
age -d -i "$identity" "$archive" > "$temp/bundle.tar"
# Reject links and unexpected paths before extraction.
python3 - "$temp/bundle.tar" <<'PY'
import sys,tarfile
allowed={"database.dump","storage.tar","SHA256SUMS","manifest.json"}
with tarfile.open(sys.argv[1]) as t:
 names=t.getnames()
 if set(names)!=allowed or any(not m.isfile() for m in t.getmembers()):
  raise SystemExit("Invalid bundle members")
PY
tar -C "$temp" -xf "$temp/bundle.tar"
(cd "$temp" && sha256sum -c SHA256SUMS)
pg_restore --list "$temp/database.dump" >/dev/null
python3 - "$temp/manifest.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
assert d["format"]=="supabase-lite-backup-v1"
PY
echo "ARCHIVE INTEGRITY PASS; NOT A RESTORE PASS."
