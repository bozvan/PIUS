# PIUS Microservices

Orchestration repository for the PIUS survey analytics platform. The service code
lives in separate repositories and is mounted here as Git submodules.

## Services

| Service | Repository | HTTP port |
| --- | --- | --- |
| User Service | `git@github.com:Iv05An/user-service.git` | `8080` |
| Survey Service | `git@github.com:isco25/survey-service.git` | `8081` |
| Analytics Service | `git@github.com:bozvan/analytics-service.git` | `8082` |

## Repository Layout

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

## Clone

```powershell
git clone --recurse-submodules git@github.com:bozvan/PIUS.git
cd PIUS
```

If the repository was cloned without submodules:

```powershell
git submodule update --init --recursive
```

## Run Locally

1. Copy `.env.example` to `.env` if you want to override defaults.
2. Start the stack:

```powershell
docker compose up --build -d
```

3. Run the integration smoke test:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-integration.ps1
```

4. Stop the stack:

```powershell
docker compose down
```

Use `docker compose down -v` to also remove local SQLite volumes.

## Interservice Calls

- `survey-service -> user-service`: `POST /internal/events/answer-created` awards XP.
- `survey-service -> analytics-service`: `POST /internal/events/submission-created` updates analytics.
- `analytics-service -> survey-service`: reads answer counts and user surveys for analytics.

Internal calls share `INTERNAL_API_KEY` and use deterministic `Idempotency-Key` headers so
event replays do not duplicate XP or analytics records.
