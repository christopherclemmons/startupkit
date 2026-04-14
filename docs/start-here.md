# Start Here

This guide is for engineers who want to get the app running quickly.

## 1) Prerequisites

- Docker + Docker Compose
- Node.js 18+
- .NET 10 SDK

Create a root `.env` file from `.env.example` before starting:
- `APP_NAME` (optional; leave blank to use default container prefix `app`)
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_PORT`
- `DB_HOST`
- `DB_PORT`
- `DB_AUTO_MIGRATE`
- `SITE_NAME`
- `SITE_URL`
- `BACKEND_INTERNAL_URL`
- `PGADMIN_DEFAULT_EMAIL`
- `PGADMIN_DEFAULT_PASSWORD`
- `PGADMIN_PORT`

Recommended local values in root `.env`:

```env
APP_NAME=
SITE_NAME=Terrastack
SITE_URL=http://localhost:3000
POSTGRES_DB=app
POSTGRES_USER=postgres
POSTGRES_PASSWORD=change-me
POSTGRES_PORT=5332
DB_HOST=postgres
DB_PORT=5432
DB_AUTO_MIGRATE=true
BACKEND_INTERNAL_URL=http://backend:5000
PGADMIN_DEFAULT_EMAIL=admin@local.dev
PGADMIN_DEFAULT_PASSWORD=change-me
PGADMIN_PORT=5050
```

For hot reload frontend (`npm run dev`), set `src/frontend/.env.local` too:

```env
NEXT_PUBLIC_SITE_NAME=Terrastack
NEXT_PUBLIC_SITE_URL=http://localhost:3000
BACKEND_INTERNAL_URL=http://localhost:5000
```

## 2) Choose One Local Run Mode

### Option A: Hot Reload Development (recommended)

Use this when actively developing frontend/backend code.

```sh
# terminal 1 - project root
docker-compose -f docker-compose-db.yml up -d

# terminal 2
cd src/backend/API
dotnet run

# terminal 3
cd src/frontend
npm run dev
```

What runs in this mode:
- Postgres in Docker
- Backend locally with `dotnet run`
- Frontend locally with `npm run dev`

### Option B: Full Local Docker Environment

Use this when you want everything containerized locally.

```sh
# project root
docker-compose up --build
```

What runs in this mode:
- Postgres in Docker
- Backend in Docker
- Frontend in Docker

## 3) Next Docs (Only If Needed)

- Full local reference and commands: [`../README.md`](../README.md)
- AWS deployment:
  - Windows: [`../DEPLOY.windows.md`](../DEPLOY.windows.md)
  - Bash/macOS/Linux: [`../DEPLOY.md`](../DEPLOY.md)
- Recover orphaned Terraform resources: [`../infra/dev/README.md`](../infra/dev/README.md)

