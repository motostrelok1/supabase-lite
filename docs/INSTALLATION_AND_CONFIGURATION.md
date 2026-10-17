# Supabase Lite — установка, настройка и эксплуатация

Статус: **проектная инструкция и требования к будущему установщику**, 2026-10-17. В `motostrelok1/supabase-lite` ещё не реализован/не принят универсальный `install.sh` и Compose. **Не выполнять вымышленные команды установки** и не применять тестовый восстановленный stack к новому клиенту.

## Два профиля
- **Core**: семь универсальных сервисов PostgreSQL, GoTrue, PostgREST, Realtime, Storage API, Edge Runtime, API gateway. Не включает бизнес-таблицы автошколы.
- **Driving School Kit**: Core + полная *версионированная чистая* схема Driving School, RLS, grants, triggers на `auth.users`, Storage buckets, Edge Functions, cron, сборка React/Vite PWA, первый администратор, тесты. Данные чужой автошколы/архив production не переносить.

## До установки
Новый VDS и независимые DNS имена PWA/API, Ubuntu/Docker/Compose и ресурсы по результатам capacity preflight, HTTPS, порт 443, выделенные volumes/networks. Запретить совпадение с работающими Docker project, именами томов и каталогами. Выбрать источник исходящей почты: Mailpit в sandbox или проверенный SMTP production. Подготовить безопасные внешние backup storage и управление секретами. Не использовать `docker compose down -v` в эксплуатационных сценариях.

## Будущий контракт install (НЕ существующие команды)
1. Read-only preflight Docker, свободных портов, CPU/RAM/disk, каталогов, DNS и совместимых закреплённых версий образов. При конфликте отказ без частичных изменений.
2. Создание уникального project ID, паролей ролей PostgreSQL, JWT secret, anon/service_role keys и отдельных секретов Edge/cron. Секреты остаются в root-only `.env` (0600), не печатаются, не передаются через CLI или Git.
3. Поднять Core по порядку: database bootstrap и системные роли, Auth/REST/Storage, Realtime, Functions и gateway. На Realtime до запуска создать `_realtime`, публикацию с требуемыми таблицами, ключ шифрования строго 16 байт. Проверить tenants, Host rewrite для WebSocket. Edge нужен рабочий routing и необходимые режимы ключей; внешняя сеть только при обоснованной необходимости.
4. HTTPS gateway/SPA host, Auth SITE_URL/redirect allowlist, CORS и WebSocket. Публиковать наружу только Nginx/API; базы и внутренние сервисы — приватны.
5. Для Kit применить миграции полной прикладной схемы с **нуля**, включая auth triggers и grants. Не полагаться на конкретный `cloud-backup.dump`, поскольку он отстаёт от репозиторных миграций; принудительно сверять все объекты.
6. Настроить buckets, Functions и безопасный cron; PWA собрать с `VITE_SUPABASE_URL` и **публичным** anon key, не помещать service_role в frontend.
7. Пройти bootstrap администратора через явный защищённый процесс; убедиться, что публичная регистрация не повышает роль.
8. Выполнить E2E smoke и зафиксировать версию каждой части.

## Почта и push
Тест: Mailpit и OneSignal mock, реальные уведомления запрещены. Production: настоящий SMTP с доменом отправителя, TLS/SPF/DKIM/DMARC, корректными URL/redirect; обязательный email confirmation (`MAILER_AUTOCONFIRM=false`), проверка signup, resend, confirm, recovery. Установщик должен отказывать в статусе production-ready до успешной отправки тестового письма и прохождения ссылки.

OneSignal настраивается **для конкретной инсталляции**, ключи не наследуются. Push до email confirmation — запланированная бизнес-функция Driving School Kit (спека: https://github.com/motostrelok1/driving-school/blob/plan/registration-preconfirm-push/docs/REGISTRATION_PRECONFIRM_PUSH_SPEC.md); без безопасного enrollment flow отключён. Пользовательское согласие и ограничения частоты обязательны.

## Защита и проверка
RLS с JWT реальных пользователей, а не только service_role; запреты на чужие профили/чаты/документы; Storage private bucket и запрет ученического upload в lesson-media; проверка WebSocket RLS; JWT/роль/секрет для Edge. CORS разрешает только собственные домены, тестовые origin не остаются в production. Проверять, что в собранном JS нет чужого URL, а в Git нет секретов.

## Обслуживание, backup/restore
Делать консистентную копию PostgreSQL (включая `auth`, `storage` metadata, policies, миграционный ledger), файлов Storage и защищённую копию секретов. Проверять восстановление в **новом изолированном** проекте с новыми volumes и сопоставлением объектов, файлов и пользователей. Восстановление существующих токенов зависит от согласованных секретов. Перед обновлением проверять совместимость schema и сервисных версий. Откат БД — только из протестированной резервной копии, не только по возврату git commit.

## Что ещё НЕ готово
`compose.yml` общего назначения, проверенный secret generator и install/verify/backup/restore/upgrade скрипты, clean-room запуск на другом VDS, release matrix, обязательный email-confirmation на реальном SMTP, проверка browser PWA и независимая backup/restore приёмка. До выполнения этих пунктов Lite нельзя рекламировать как готовый установщик.

## Где фактические примеры
`motostrelok1/driving-school/docker/test-supabase/` и `scripts/install-test-supabase-auth-rest.sh` — работающий изолированный стенд для изучения, **не production template**. Для PWA см. `motostrelok1/driving-school/docs/DEPLOYMENT_AND_CONFIGURATION.md`.
