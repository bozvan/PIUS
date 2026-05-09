# PIUS Microservices

Общий репозиторий для запуска микросервисной системы PIUS. Код сервисов хранится в отдельных репозиториях и подключается сюда как Git submodules.

## Состав системы

| Сервис | Репозиторий | Порт |
| --- | --- | --- |
| User Service | `git@github.com:Iv05An/user-service.git` | `8080` |
| Survey Service | `git@github.com:isco25/survey-service.git` | `8081` |
| Analytics Service | `git@github.com:bozvan/analytics-service.git` | `8082` |

## Структура

```text
.
|-- docker-compose.yml
|-- .env.example
|-- scripts/
|   `-- verify-integration.ps1
`-- services/
    |-- user-service/       # Git submodule
    |-- survey-service/     # Git submodule
    `-- analytics-service/  # Git submodule
```

## Как склонировать

```powershell
git clone --recurse-submodules git@github.com:bozvan/PIUS.git
cd PIUS
```

Если репозиторий уже был склонирован без submodules:

```powershell
git submodule update --init --recursive
```

## Как собрать и запустить

```powershell
docker compose config
docker compose up --build -d
```

После запуска доступны:

- User Service: http://localhost:8080/docs
- Survey Service: http://localhost:8081/docs
- Analytics Service: http://localhost:8082/docs

## Интеграционная проверка

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-integration.ps1
```

Скрипт проверяет healthcheck всех сервисов, регистрацию пользователя, создание опроса, идемпотентное сохранение ответа, начисление XP, обновление аналитики и выдачу достижений.

Ожидаемый результат:

```text
user-service is healthy
survey-service is healthy
analytics-service is healthy
Integration smoke test passed
```

## Как остановить

```powershell
docker compose down
```

Чтобы удалить локальные SQLite volumes:

```powershell
docker compose down -v
```

## Что показать преподавателю

1. Отдельные репозитории сервисов:
   - https://github.com/Iv05An/user-service
   - https://github.com/isco25/survey-service
   - https://github.com/bozvan/analytics-service
2. Общий репозиторий запуска:
   - https://github.com/bozvan/PIUS
3. Файл `.gitmodules` в `PIUS`, где видно, что сервисы подключены как submodules.
4. `docker-compose.yml`, где каждый сервис собирается из своего submodule.
5. Команду `docker compose up --build -d` и открытые Swagger UI на портах `8080`, `8081`, `8082`.
6. Результат `verify-integration.ps1` со строкой `Integration smoke test passed`.

## Межсервисное взаимодействие

- `survey-service -> user-service`: `POST /internal/events/answer-created` начисляет XP.
- `survey-service -> analytics-service`: `POST /internal/events/submission-created` обновляет аналитику.
- `analytics-service -> survey-service`: читает количество ответов и опросы пользователя.

Внутренние вызовы используют `INTERNAL_API_KEY` и deterministic `Idempotency-Key`, чтобы повторные события не дублировали XP и статистику.
