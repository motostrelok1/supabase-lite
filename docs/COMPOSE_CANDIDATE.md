# Experimental Compose candidate — **DO NOT DEPLOY**

This PR adds a seven-service Compose skeleton, a static Envoy route map and a minimal Edge placeholder. The versions come from the **historical** image inventory, not a current working captured configuration.

**Missing, deliberately not claimed complete:**
- Supabase-specific Postgres initialization: roles, grants, auth/storage/realtime schemas, migrations and extensions. Without this, Auth and Storage cannot start correctly.
- Realtime tenant bootstrap and correct WebSocket/host routing.
- Correct API key verification: plain Envoy routing does **not** implement the usual Supabase gateway API-key auth. The gateway is bound to 127.0.0.1 only.
- Storage metadata schema and migration/permissions, Auth SMTP/recovery settings, Functions deployment and secrets.
- A completed `docker compose config --quiet` check, image pull, health tests, isolated installation and restoration.

**Do not run `docker compose up` against existing VDS.** This is a reviewable starting point for the next follow-up: extract a *sanitized* configuration from the proven seven-service stack and compare route-by-route, env-by-env, bootstrap-by-bootstrap. Before enabling the pipeline, validate configuration and images in an isolated Docker project, then run E2E tests and restore. No real secrets or production URLs are included.
