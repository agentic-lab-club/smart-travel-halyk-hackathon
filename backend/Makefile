# Makefile for Directus with ENV support

BACKEND_SERVICE_NAME=golang
#DATABASE_SERVICE_NAME=postgres

# for localhost usage!
NAMED_COMPOSE_FILE = docker-compose.yml


## -------------------------
## Base Commands
## -------------------------

up: ## Start Container's
	@docker compose -f $(NAMED_COMPOSE_FILE) up -d

down: ## Stop Container's
	@docker compose -f $(NAMED_COMPOSE_FILE) down

build: ## Build Container's
	@docker compose -f $(NAMED_COMPOSE_FILE) build
#	@docker compose -f $(NAMED_COMPOSE_FILE) build --no-cache

logs: ## Show logs
	@docker compose -f $(NAMED_COMPOSE_FILE) logs -f

rebuild: ## Rebuild Container's
	@docker compose -f $(NAMED_COMPOSE_FILE) up --build -d

# docker compose run --rm --no-deps golang-test go test ./internal/healthcheck
# go test -v (for detailed log)
test: ## Run Go tests inside docker
	@docker compose -f $(NAMED_COMPOSE_FILE) run --rm --no-deps golang-test go test ./...

test-build: ## Build the test image (after deps changes)
	@docker compose -f $(NAMED_COMPOSE_FILE) build golang-test

sh:
	@docker compose -f $(NAMED_COMPOSE_FILE) exec -it $(BACKEND_SERVICE_NAME) sh

# TODO: генерировать swagger outside docker (внутрь /docs как спека и коммитить его! в каждом изменений)
# Swagger/OpenAPI-спека должна быть доступна вне контейнера (в репозитории или по URL).
swagger:
	@powershell -NoProfile -Command "$$env:GOCACHE='$(CURDIR)\\.cache\\go-build'; $$env:GOMODCACHE='$(CURDIR)\\.cache\\gomod'; $$env:GOTELEMETRY='off'; go install github.com/swaggo/swag/cmd/swag@v1.8.1; $$env:PATH += ';' + (Join-Path $$env:USERPROFILE 'go\\bin'); swag init -g cmd/server/main.go; $$json = Get-Content 'docs/swagger.json' -Raw | ConvertFrom-Json; $$json.host = '127.0.0.1:8080'; $$json.schemes = @('http'); $$json | ConvertTo-Json -Depth 100 | Set-Content 'docs/swagger-local.json'; $$json = Get-Content 'docs/swagger.json' -Raw | ConvertFrom-Json; $$json.host = 'api-stage.yourdomain.com'; $$json.schemes = @('https','http'); $$json | ConvertTo-Json -Depth 100 | Set-Content 'docs/swagger-stage.json'; $$json = Get-Content 'docs/swagger.json' -Raw | ConvertFrom-Json; $$json.host = 'api.yourdomain.com'; $$json.schemes = @('https'); $$json | ConvertTo-Json -Depth 100 | Set-Content 'docs/swagger-prod.json'"

#psql:
#	@docker compose -f $(NAMED_COMPOSE_FILE) exec -it $(DATABASE_SERVICE_NAME) psql -d directus_dev -U directus_dev

.PHONY: up down build logs rebuild sh swagger test test-build yc-push-staging yc-push-prod yc-setup yc-list-images verify-build install-hooks
