# PIUS Microservices

Общий репозиторий для запуска микросервисной системы PIUS. Сами сервисы подключены как Git submodules:

- `services/user-service`
- `services/survey-service`
- `services/analytics-service`

## Состав системы

| Сервис | Назначение | Порт |
| --- | --- | --- |
| `user-service` | пользователи, JWT, XP, репутация, подписки, лента, лидерборд | `8080` |
| `survey-service` | опросы, ответы, валидация, бонусные вопросы, изображения, рекомендации | `8081` |
| `analytics-service` | аналитика, экспорт JSON, достижения, уведомления | `8082` |

## Что реализовано

- Репутация авторов: `POST /api/v1/users/{user_id}:rate`
- Подписки на пользователей: `POST /api/v1/users/{user_id}:subscribe`
- Списки подписчиков и подписок: `GET /api/v1/users/{user_id}/followers`, `GET /api/v1/users/{user_id}/following`
- Лента опросов по подпискам: `GET /api/v1/users/{user_id}/feed`
- Улучшенный лидерборд с фильтром по периоду: `POST /api/v1/users:leaderboard`
- 3 сложных достижения: `Hard worker`, `Explorer`, `Celebrity`
- Уведомления пользователя: `GET /api/v1/users/{user_id}/notifications`
- Продвинутая аналитика: среднее время прохождения опроса
- Экспорт аналитики в JSON: `GET /api/v1/surveys/{survey_id}/analytics/export`
- Бонусные вопросы: `is_bonus`, дополнительный `+2 XP`
- Усиленная валидация email/phone по регулярным выражениям
- Изображение у опроса: поле `image_url`
- Аналитические эндпоинты опросов: популярные опросы и рекомендации

## API conventions

Все сервисы приведены к `API Design Guide`: https://docs.ensi.tech/guidelines/api

- все публичные маршруты версионированы через `/api/v1`
- ответы JSON имеют формат `data / errors / meta`
- названия ресурсов даны во множественном числе
- дополнительные действия оформлены через `POST ...:action`
- поля `query` и `body` используют `snake_case`

## Клонирование

```powershell
git clone --recurse-submodules git@github.com:bozvan/PIUS.git
cd PIUS
```

Если репозиторий уже клонирован без submodules:

```powershell
git submodule update --init --recursive
```

## Запуск

Docker-конфигурация не менялась.

```powershell
docker compose config
docker compose up --build -d
```

После запуска доступны:

- User Service: `http://localhost:8080/docs`
- Survey Service: `http://localhost:8081/docs`
- Analytics Service: `http://localhost:8082/docs`

Остановка:

```powershell
docker compose down
```

Удаление локальных volumes:

```powershell
docker compose down -v
```

## Git hooks

Добавлены `pre-push` hooks для корневого репозитория и для каждого микросервиса. Hooks запускают тесты перед push.

Установка:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-git-hooks.ps1
```

Если Git metadata у submodule ещё не инициализирована, скрипт настроит hooks только для корня и выведет предупреждение. В этом случае зайдите в нужный сервис и выполните:

```powershell
git config core.hooksPath .githooks
```

Ручной запуск полного набора тестов:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-service-tests.ps1
```

## Тесты

Из корня:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-service-tests.ps1
```

Локально по сервисам:

- `services/user-service`: `python -m unittest discover -s tests -v`
- `services/survey-service`: `python -m pytest`
- `services/analytics-service`: `python -m unittest discover -s tests -p "test_analytics.py" -v`
