# Инвентаризация удалённого пустого Supabase на VDS — 18.10.2026

Источник: вывод `docker compose config --services` и `docker compose config --images` в `/opt/supabase` до очистки каталога. Версии зафиксированы оператором; список включает сервисы отключённых профилей, **не означает**, что все 11 запускались.

## Все объявленные Compose-сервисы
`db`, `studio`, `api-gw`, `functions`, `meta`, `imgproxy`, `rest`, `storage`, `supavisor`, `auth`, `realtime`.

## Образы (из того же вывода)
- `supabase/postgres:17.6.1.136`
- `postgrest/postgrest:v14.17`
- `supabase/realtime:v2.134.10`
- `supabase/edge-runtime:v1.76.2`
- `envoyproxy/envoy:v1.39.1`
- `supabase/gotrue:v2.196.0`
- `supabase/storage-api:v1.74.0`
- `supabase/postgres-meta:v0.99.0`
- `darthsim/imgproxy:v3.31.4`
- `supabase/studio:2026.09.07-sha-7996410`
- `supabase/supavisor:2.9.12`

## Фактически работавшие сервисы
Семь: `db`, `api-gw`, `functions`, `rest`, `storage`, `auth`, `realtime`. Отключённые профили: `studio`, `meta`, `imgproxy`, `supavisor`.

## Архив и удаление
- Оригинальные Compose: `/opt/backups/supabase-lite/compose-original.tar.gz` (5.8 КБ).
- Архив конфигурации каталога без основных данных DB/Storage: `/opt/backups/supabase-lite/supabase-config-full.tar.gz` (158 КБ), tar test OK, SHA-256 создан.
- Все 7 старых контейнеров удалены; `supabase_db-config` и `supabase_deno-cache` удалены.
- TEST остаётся в отдельном Compose-проекте.
- **Это не воспроизводимый backup.** Настоящие `docker-compose.yml` и `docker-compose.override.yml` пока не перенесены в репозиторий и требуют локального удаления секретов перед публикацией.
- Не публиковать `.env`, пароли, JWT, ключи и полный вывод `docker compose config`.
