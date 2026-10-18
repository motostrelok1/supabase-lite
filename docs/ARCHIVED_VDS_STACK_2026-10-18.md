# Архив остановленного self-hosted Supabase (VDS) — 2026-10-18

Источник: существующий Docker Compose project `supabase` на VDS автошколы. Это **не** TEST (`driving-school-supabase-test`) и не Supabase Cloud.

## Подтверждено оператором
- Семь контейнеров (`supabase-storage`, `realtime-dev.supabase-realtime`, `supabase-auth`, `supabase-rest`, `supabase-db`, `supabase-edge-functions`, `supabase-envoy`) успешно остановлены скриптом проекта driving-school из PR #208.
- `auth.users`, `auth.identities`, `storage.buckets`, `storage.objects`: 0. Прикладные таблицы `public` не обнаружены в предоставленной выборке.
- `auth.schema_migrations`: приблизительно 77 строк; `storage.migrations`: приблизительно 70 строк — штатные служебные записи.
- TEST продолжает работать; его 12 контейнеров не тронуты.
- У БД имеется Docker volume `supabase_db-config` и bind mounts SQL init/migrations и PostgreSQL data.

## Что здесь *пока не сохранено*
Фактические compose-файлы VDS и перечень pinned image tags **ещё не загружены в репозиторий**. Этот документ — журнал состояния, **не резервная копия запускаемого стека**.

## Безопасное архивирование до удаления
1. Установить путь `com.docker.compose.project.working_dir` / `config_files` через `docker inspect supabase-db`.
2. Сделать закрытый локальный архив оригинальных compose-файлов, env, bind mounts и, если нужен точный restore, PostgreSQL data/volume. Хранить вне GitHub.
3. Для публичного репозитория подготовить отдельный, вручную проверенный шаблон compose с именами переменных, заменив реальные ключи и доступы. `docker compose config` без осторожности раскрывает подставленные секреты; его вывод нельзя публиковать.
4. Только когда архив проверен, удалять ресурсы исключительно проекта `supabase`. Не использовать глобальные команды `docker system prune --volumes` или `docker volume prune`, не касаться TEST.
5. Проверить после удаления доступность `test.dvizh-school.ru` и `supabase-test.dvizh-school.ru`.

Миграция пользователей и прогресса из Cloud — отдельный следующий этап, не часть удаления пустого стека.
