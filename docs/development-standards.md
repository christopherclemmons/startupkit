# Development Standards

The core principles to adhere to:
* Simplicity in coding patterns and use of third party code packages. This means 
  * Only consume new packages that are essential to the feature or capability
  * Do not include packages that are meant to be quality of life improvements for engineers
* All components used should be added to README file under "Core Components Used"
* All core features created should also include automated tests that can be run locally
  * Unit tests for both positive and negative cases
  * Integration tests using chromedriver that run against docker compose
  * Integration tests use Play
* Tests should be run and pass before a task is considered ready
  * Run `make test`, review any errors and resolve
  * Continue process until successful
* UX should be modern and simple and consider mobile users first
* All components, except for native application, should run in Docker
* .Net coding and project structure rules
  * A single solution file will reside at top level of backend folder structure
  * Each project will be placed in a directory with the same name as the project, without the base solution namespace
* Terraform code will be used to create infrastructure
  * Base directory is /infra
  * A folder per environment will be created (dev, prod)
  * Our company uses AWS by default
* .Net APIs should run Swagger/OpenAPI spec when in development mode
* Software code will live in the /src directory
  * Directories for frontend (Admin Next.js Web Application), backend (Routing API and Admin API) and client (VPN app) will be used
* Items such as binaries, compiled code and secrets should be added to the .gitignore file at root
