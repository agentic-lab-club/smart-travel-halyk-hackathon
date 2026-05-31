c =Add new changes

sent:
	git add .
	git commit -m "${c}"
	git push

swagger-backend:
	$(MAKE) -C backend swagger

BACKEND_SERVICE_NAME=backend
BACKEND_TEST_SERVICE_NAME=backend-test
AGENT_SERVICE_NAME=agent

# for localhost usage!
NAMED_COMPOSE_FILE = docker-compose.yml

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

# docker compose run --rm --no-deps backend-test go test ./internal/healthcheck
# go test -v (for detailed log)
test: test-all ## Run all existing automated tests inside docker

test-all: test-backend test-agent ## Run backend and agent tests

test-backend: ## Run all backend Go tests inside docker
	@docker compose -f $(NAMED_COMPOSE_FILE) run --rm --no-deps $(BACKEND_TEST_SERVICE_NAME) go test -v ./...

test-agent: ## Run all agent Python tests inside docker
	@docker compose -f $(NAMED_COMPOSE_FILE) run --rm --no-deps $(AGENT_SERVICE_NAME) python -m unittest test_planning_service.py test_api.py

test-build: test-build-backend ## Backward-compatible alias for backend test image build

test-build-backend: ## Build the backend test image
	@docker compose -f $(NAMED_COMPOSE_FILE) build $(BACKEND_TEST_SERVICE_NAME)

test-backend-integration-build: ## Build backend integration test images in backend module
	@$(MAKE) -C backend integration-test-build

test-backend-integration: ## Run backend integration suite in backend module
	@$(MAKE) -C backend integration-test

sh:
	@docker compose -f $(NAMED_COMPOSE_FILE) exec -it $(BACKEND_SERVICE_NAME) sh

# TODO: генерировать swagger outside docker (внутрь /docs как спека и коммитить его! в каждом изменений)
# Swagger/OpenAPI-спека должна быть доступна вне контейнера (в репозитории или по URL).
swagger:
	@powershell -NoProfile -Command "$$env:GOCACHE='$(CURDIR)\\.cache\\go-build'; $$env:GOMODCACHE='$(CURDIR)\\.cache\\gomod'; $$env:GOTELEMETRY='off'; go install github.com/swaggo/swag/cmd/swag@v1.8.1; $$env:PATH += ';' + (Join-Path $$env:USERPROFILE 'go\\bin'); swag init -g cmd/server/main.go; $$json = Get-Content 'docs/swagger.json' -Raw | ConvertFrom-Json; $$json.host = '127.0.0.1:8080'; $$json.schemes = @('http'); $$json | ConvertTo-Json -Depth 100 | Set-Content 'docs/swagger-local.json'; $$json = Get-Content 'docs/swagger.json' -Raw | ConvertFrom-Json; $$json.host = 'api-stage.yourdomain.com'; $$json.schemes = @('https','http'); $$json | ConvertTo-Json -Depth 100 | Set-Content 'docs/swagger-stage.json'; $$json = Get-Content 'docs/swagger.json' -Raw | ConvertFrom-Json; $$json.host = 'api.yourdomain.com'; $$json.schemes = @('https'); $$json | ConvertTo-Json -Depth 100 | Set-Content 'docs/swagger-prod.json'"

#psql:
#	@docker compose -f $(NAMED_COMPOSE_FILE) exec -it $(DATABASE_SERVICE_NAME) psql -d directus_dev -U directus_dev

.PHONY: sent swagger-backend up down build logs rebuild sh swagger test test-all test-backend test-agent test-build test-build-backend test-backend-integration-build test-backend-integration yc-push-staging yc-push-prod yc-setup yc-list-images verify-build install-hooks
