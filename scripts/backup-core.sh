#!/usr/bin/env bash
# Independent encrypted backup bundle. Never touches production services or alters data.
set -Eeuo pipefail
umask 077

usage() {
  cat <<'EOF'
Usage: AGE_RECIPIENT='age1...' PGHOST=... PGUSER=... PGDATABASE=... \
       PGPASSWORD=... STORAGE_DIR=/absolute/storage/path \
       OUTPUT_DIR=/absolute/offsite-staging bash scripts/backup-core.sh
Requirements: pg_dump, age, tar, sha256sum, python3.
This script creates an encrypted archive locally. It does NOT upload to GitHub.
The caller must ensure Storage writes are quiesced or use a consistent storage snapshot.
EOF
}
if [[ ${1:-} == "--help" ]]; then usage; exit 0; fi
[[ $# -eq 0 ]] || { usage >&2; exit 2; }
for x in AGE_RECIPIENT PGHOST PGUSER PGDATABASE PGPASSWORD STORAGE_DIR OUTPUT_DIR; do
  [[ -n "${!x:-}" ]] || { echo "ERROR: missing $x" >&2; exit 2; }
done
for cmd in pg_dump age tar sha256sum python3; do
  command -v "$cmd" >/dev/null || { echo "ERROR: missing $cmd" >&2; exit 2; }
done
[[ "$AGE_RECIPIENT" == age1* ]] || { echo "ERROR: AGE_RECIPIENT must be an age X25519 public recipient" >&2; exit 2; }
[[ -d "$STORAGE_DIR" && "$STORAGE_DIR" = /* ]] || { echo "ERROR: STORAGE_DIR must be an existing absolute directory" >&2; exit 2; }
[[ "$OUTPUT_DIR" = /* ]] || { echo "ERROR: OUTPUT_DIR must be absolute" >&2; exit 2; }
python3 - <<'PY'
import os, pathlib, sys
a=pathlib.Path(os.environ["STORAGE_DIR"]).resolve()
b=pathlib.Path(os.environ["OUTPUT_DIR"]).resolve()
if a==b or a in b.parents or b in a.parents:
 sys.exit("ERROR: backup output and storage may not be nested")
PY
mkdir -p "$OUTPUT_DIR"
[[ -d "$OUTPUT_DIR" && ! -L "$OUTPUT_DIR" ]] || { echo "ERROR: output directory cannot be symlink" >&2; exit 2; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
id="supabase-lite-$stamp-$$"
# Backup PostgreSQL roles separately as globals requires pg_dumpall privileges;
# document roles/bootstrap dependencies in the restore runbook.
pg_dump --format=custom --no-owner --no-acl --file="$work/database.dump"
tar -C "$STORAGE_DIR" -cf "$work/storage.tar" .
(
 cd "$work"
 sha256sum database.dump storage.tar > SHA256SUMS
)
python3 - "$work" "$id" <<'PY'
import datetime,json,os,pathlib,subprocess,sys
folder=pathlib.Path(sys.argv[1])
manifest={"format":"supabase-lite-backup-v1","id":sys.argv[2],
 "created_at":datetime.datetime.now(datetime.timezone.utc).isoformat(),
 "database":os.environ["PGDATABASE"],"artifacts":["database.dump","storage.tar","SHA256SUMS"],
 "storage_consistency":"operator-must-freeze-writes-or-use-snapshot",
 "postgres_version":subprocess.check_output(["pg_dump","--version"],text=True).strip()}
(folder/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
PY
out="$OUTPUT_DIR/$id.tar.age"
[[ ! -e "$out" ]] || { echo "ERROR: archive already exists" >&2; exit 1; }
tar -C "$work" -cf - database.dump storage.tar SHA256SUMS manifest.json | age -r "$AGE_RECIPIENT" -o "$out"
chmod 600 "$out"
test -s "$out"
sha256sum "$out" > "$out.sha256"
chmod 600 "$out.sha256"
echo "CREATED: $out"
echo "IMPORTANT: encrypted archive remains local; upload to independently controlled offsite storage."
echo "RESTORE NOT VERIFIED: execute isolated restore test before production use."
