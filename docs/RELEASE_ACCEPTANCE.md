# Supabase Lite — план выпуска восстанавливаемого Core

**Статус на 28.10.2026: подготовка, не готовый установщик.** Не запускать на текущем VDS вместо действующего Supabase. GitHub не содержит работающую копию контейнеров и volumes.

## Что реально хранится здесь

- Зафиксированная архитектура 7 сервисов в `docs/PLAN.md`.
- Обезличенная инвентаризация исторического VDS, **не runnable compose**.
- Пример названий переменных `.env.example`, read-only `scripts/preflight.sh`, валидатор `scripts/validate-template.py`.
- Статические CI-проверки. Они **не** заменяют интеграционный smoke.

## Как довести до релиза v0.1

- [x] Безопасный шаблон переменных и preflight без изменения Docker.
- [x] Статические проверки CI.
- [ ] Снять **актуальную** обезличенную конфигурацию работающего стека Driving School, не переносить .env, дампы, пароли, app-specific функции.
- [ ] Собрать переносимый compose.yml, Envoy routes, SQL bootstrap системных ролей, storage/realtime, закрепить image digests.
- [ ] Реализовать локальный генератор **уникальных** паролей и JWT с безопасным вводом/выводом. Никаких дефолтных рабочих ключей.
- [ ] Install только для пустого уникального COMPOSE_PROJECT_NAME, без конфликтов с running Docker, без down -v.
- [ ] Контракт status/verify: Auth signup/login/refresh/recovery, REST JWT и RLS, Storage upload/download, Realtime WS, Functions, restart persistence.
- [ ] PostgreSQL backup + Storage files + separate encrypted secret escrow; протестировать restore на другом volume/project.
- [ ] Реальный SMTP + TLS/Nginx только после отдельной конфигурации и проверки.
- [ ] Clean-room install и restore на **отдельной** машине/изолированном Docker project; протокол и image version matrix.
- [ ] Выпустить v0.1.0 **только после** PASS всех проверок.

## Контроль безопасности

Публичный репозиторий: запрещены `.env`, настоящие домены/ключи и дампы. `ANON_KEY` публичен только в конкретном приложении, `SERVICE_ROLE_KEY` — строго серверный. Секреты каждого нового инстанса уникальны. Не переносить пользователей автошколы. Копия исходников ≠ бэкап production данных.

## Пример локальной проверки (не установка)

```bash
python3 scripts/validate-template.py
bash scripts/preflight.sh
```

Последняя команда требует рабочий Docker Engine и ничего не запускает. Пока `compose.yml` отсутствует, никакой `docker compose up` для Lite выполнять нельзя.
