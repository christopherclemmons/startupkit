# Repository Guidelines

## Project Structure & Module Organization

Application code lives under `src/`. The Next.js frontend is in `src/frontend` with App Router code in `src/frontend/src/app`, shared components in `src/frontend/src/components`, and Playwright specs in `src/frontend/tests`. The .NET 10 backend is in `src/backend/API`, with controllers, data, models, and services split by folder; backend tests live in `src/backend/API.Tests`. Terraform code is under `infra/` with environment stacks in `infra/dev` and `infra/prod`, plus reusable modules in `infra/modules`. Supporting docs and workflow references live in `docs/`.

## Build, Test, and Development Commands

- `docker compose -f docker-compose.yml up -d --build`: run frontend, backend, PostgreSQL, and pgAdmin.
- `docker compose -f docker-compose-db.yml up -d`: run only PostgreSQL and pgAdmin for hot-reload development.
- `cd src/frontend && npm run dev`: start the Next.js app locally.
- `cd src/backend/API && dotnet run`: start the API locally.
- `make build`: build frontend and backend.
- `make test`: run frontend, backend, and integration tests.

## Coding Style & Naming Conventions

Frontend code uses TypeScript/Next.js functional components, typically with 2-space indentation, `PascalCase` component files, and `camelCase` variables. Backend code uses C# with file-scoped namespaces, `PascalCase` types and methods, and clear folder-by-feature placement (`Controllers`, `Services`, `Models`, `Data`). Keep dependencies minimal and update `README.md` when adding a new core component.

## Testing Guidelines

Frontend unit tests run through Jest: `cd src/frontend && npm run test:unit`. Integration tests use Playwright: `cd src/frontend && npm run test:integration`. Backend tests use xUnit and Moq: `cd src/backend && dotnet test`. Add positive and negative test cases for new behavior. Test files should follow existing patterns such as `ProfileControllerTests.cs` and `example.spec.ts`.

## Commit & Pull Request Guidelines

Recent history favors short, imperative subjects and scoped prefixes when useful, for example `docs: use AWS in development standards` or `refactor(api): centralize controller attributes in BaseApiController`. Keep commits focused. PRs should describe what changed, why it changed, and how it was validated. Include screenshots for frontend changes and call out any config, Docker, or Terraform impact.

## Security & Configuration Tips

Compose reads secrets from the root `.env`; start from `.env.example` and do not commit real credentials. Prefer Docker-based workflows for shared services, and avoid committing generated output such as `bin/`, `obj/`, or local database files.

## Do 
- make sure all tests pass with at least an 80% score
- paramerize db inputs to prevent SQL injection
- write UI code to prevent abuse from bad actors
- use rate limiting to prevent DDoS
- use function components on the Next.js frontend
- enforce accessibility standards (A11y and WAG) for usability on React components
- keep business logic in the service layer, not inside controllers or repositories.
- make controllers thin; let them handle HTTP and transport concerns while services handle workflows and orchestration
- make services easy to test by keeping dependencies visible and responsibilities narrow.

## Don't
- don't hard code any sensitive information such as PII, PHI, or anything that would violate HIPAA, or GPDR compliance laws.
- don't leak database entities or persistence models across boundaries when DTOs or request/response models are more appropriate
