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

## Как остановить

```powershell
docker compose down
```

Чтобы удалить локальные SQLite volumes:

```powershell
docker compose down -v
```
