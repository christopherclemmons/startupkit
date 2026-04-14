.PHONY: help install build run stop clean test frontend backend postgres
ifneq (,$(wildcard .env))
include .env
endif
APP_NAME ?= app
POSTGRES_CONTAINER := $(APP_NAME)-postgres

# Default target
help:
	@echo "APP_NAME - Available Commands:"
	@echo ""
	@echo "Variables:"
	@echo "  APP_NAME=<name>  - Prefix for local container names (default: app)"
	@echo ""
	@echo "Development:"
	@echo "  install     - Install all dependencies (frontend and backend)"
	@echo "  build       - Build all components"
	@echo "  run         - Run all services locally"
	@echo "  stop        - Stop all running services"
	@echo "  clean       - Clean build artifacts and containers"
	@echo ""
	@echo "Individual Services:"
	@echo "  frontend    - Run Next.js frontend only"
	@echo "  backend     - Run .NET backend only"
	@echo "  postgres    - Run PostgreSQL database only"
	@echo ""
	@echo "Testing:"
	@echo "  test        - Run all tests"
	@echo "  test-frontend - Run frontend tests"
	@echo "  test-backend  - Run backend tests"
	@echo "  test-integration - Run frontend integration tests with Playwright"

# Install dependencies
install:
	@echo "Installing frontend dependencies..."
	cd src/frontend && npm install
	@echo "Installing backend dependencies..."
	cd src/backend && dotnet restore

# Build all components
build:
	@echo "Building frontend..."
	cd src/frontend && npm run build
	@echo "Building backend..."
	cd src/backend && dotnet build

# Run all services locally
run:
	@echo "Starting PostgreSQL..."
	docker run -d --name $(POSTGRES_CONTAINER) -e POSTGRES_DB=app -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:15-alpine
	@echo "Starting .NET backend..."
	cd src/backend/API && dotnet run &
	@echo "Starting Next.js frontend..."
	cd src/frontend && npm run dev

# Stop all services
stop:
	@echo "Stopping all services..."
	-docker stop $(POSTGRES_CONTAINER)
	-docker rm $(POSTGRES_CONTAINER)
	-pkill -f "dotnet run"
	-pkill -f "next dev"
	-pkill -f "next start"

# Clean build artifacts and containers
clean:
	@echo "Cleaning build artifacts..."
	cd src/frontend && rm -rf .next node_modules
	cd src/backend && dotnet clean
	@echo "Removing Docker containers and images..."
	-docker-compose -f docker-compose-db.yml down -v
	-docker stop $(POSTGRES_CONTAINER) 2>/dev/null || true
	-docker rm $(POSTGRES_CONTAINER) 2>/dev/null || true
	-docker system prune -f

# Run individual services
frontend:
	@echo "Starting Next.js frontend..."
	cd src/frontend && npm run dev

backend:
	@echo "Starting .NET backend..."
	cd src/backend/API && dotnet run

postgres:
	@echo "Starting PostgreSQL..."
	docker-compose -f docker-compose-db.yml up -d

# Testing
test: test-frontend test-backend test-integration

test-frontend:
	@echo "Running frontend tests..."
	cd src/frontend && npm run test:unit

test-backend:
	@echo "Running backend tests..."
	cd src/backend && dotnet test

test-integration:
	@echo "Running frontend integration tests with Playwright..."
	cd src/frontend && npx playwright install --with-deps && npm run test:integration 


