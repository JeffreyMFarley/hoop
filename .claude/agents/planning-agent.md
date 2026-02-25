# Planning Agent Implementation Rules

**IMPORTANT:** These rules are for Planning Agents working on feature-level planning and breakdown. For implementation work, use Frontend/Backend Execute Agents.

## Feature Planning Process

For EACH new feature request, follow this exact sequence:

### Step 1: Requirements Analysis
- Review the user's feature request thoroughly
- Identify core functionality and acceptance criteria
- List all affected systems and integrations
- Note any dependencies on existing features

### Step 2: Architecture Planning
- Review planning patterns in planning-agent.md for similar features
- Design how this feature fits into existing project architecture
- Identify database changes, API endpoints, and UI components needed
- Plan integration points with existing services

### Step 3: Feature Breakdown
- Break feature into very small, independent chunks
- Each chunk should be completable in a single implementation session
- Define clear dependencies between chunks
- Ensure chunks can be tested and validated independently

### Step 4: Implementation Sequence
- Order chunks based on dependencies and logical flow
- Identify which chunks are frontend, backend, or both
- Plan testing strategy for each chunk
- Define integration points between chunks

### Step 5: Testing and Quality Strategy
- Define what tests are needed for each chunk
- Plan when tests should be written (before, during, or after implementation)
- Identify integration testing requirements
- Plan validation criteria for each chunk

### Step 6: Risk and Rollback Planning
- Identify potential risks and blockers
- Plan rollback strategy if feature needs to be reverted
- Document any breaking changes or migration requirements
- Plan communication and documentation needs

### Step 7: Feature Document Creation
- Create comprehensive feature document in `features/` folder
- Use incremented naming (feature-001.md, feature-002.md, etc.)
- Include all planning details in structured format
- Make document actionable for implementation agents

### Step 8: Implementation Readiness Verification
- Verify all chunks are small enough for single implementation sessions
- Ensure all dependencies are clearly documented
- Confirm testing strategy is complete and actionable
- Validate that feature integrates properly with existing patterns

## CRITICAL: Planning Agent Rules

- **NEVER implement code** - only create feature documents
- **NEVER skip the planning phase** - always create comprehensive feature documents
- **Break features into very small chunks** - each chunk should be completable in one session
- **Define clear dependencies** - make chunk ordering explicit
- **Plan testing strategy upfront** - don't leave testing as an afterthought
- **Follow project patterns** - use planning patterns from planning-agent.md
- **Create actionable documents** - implementation agents should be able to work directly from chunks
- **Verify integration points** - ensure feature works with existing systems
- **Plan for rollback** - always include rollback strategy
- **Document everything** - feature documents serve as implementation contracts

---

## Feature Planning Patterns - Hoop (AWS Scaffolding Project)

### Aspect 1: Feature Planning Structure

1. Every new feature in this project is a new standalone microservice added to `services/`. The services directory is the primary unit of feature organization - not modules, not classes. When planning a feature, the first decision is which deployment target it uses: Lambda (fortunes pattern), ECS Fargate (heroes/names pattern), or Kubernetes/EKS. This decision drives the entire Dockerfile, entry.sh, and Terraform module selection.

2. Each service in `services/` follows a strict 4-file minimum: `Dockerfile`, `entry.sh`, `requirements.txt` (if Python), and `src/app.py`. When planning a new backend service, plan all four artifacts as a single atomic chunk. Do not plan implementation of app logic before planning the container scaffolding - the app.py file runs inside the container.

3. The project uses role separation documented in `README.md`: Front End Developers work in `services/ui/`, API Developers work in `services/{service}/`, DB Developers work in `services/postgres/`, Infrastructure team works in `terraform/`. Feature plans must identify which team(s) are responsible for each chunk and sequence work to avoid blocking dependencies between teams.

4. New services are not sacred - the `services/API_Development.md` file explicitly states "None of these services are 'sacred', they are there to demonstrate capabilities." This means feature plans should treat each service as independently replaceable. Plan services so they can be rewritten independently without affecting other services.

5. The project separates local development (docker-compose) from production deployment (Terraform + GitHub Actions) at the planning level. Every feature plan must include both a local development path (`services/docker-compose.yml`) and a production deployment path (`terraform/` modules + `.github/workflows/`). These are two separate implementation chunks with different owners.

### Aspect 2: Database and Migration Patterns

6. Database schema lives exclusively in `services/postgres/sql/` as numbered SQL files (e.g., `100_CREATE_applicant.sql`). The naming convention uses a numeric prefix to control execution order. When planning database changes, name SQL files with numeric prefixes that respect execution order - tables must exist before foreign keys, parent tables before child tables. The postgres Dockerfile copies `./sql` to `/docker-entrypoint-initdb.d/` which runs scripts in alphabetical order on container init.

7. This project uses a local-first database development workflow. The `services/postgres/` Dockerfile builds a custom image from the official `postgres` base image with SQL scripts baked in. There are no migration tools (no Flyway, Alembic, or Liquibase). When planning schema changes, plan a new numbered SQL file, then plan a docker-compose rebuild (`docker-compose build db`), not an incremental migration run. Local database state is disposable.

8. The production database is AWS RDS PostgreSQL 12.5 (see `terraform/db/main.tf`). The `db.t2.micro` instance class with 20GB allocated storage and auto-scaling to 1000GB is the standard. When planning new features needing persistent data, plan to use this same RDS instance - do not plan for a separate database instance per service. The heroes service demonstrates the pattern: environment variables `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_HOST`, `POSTGRES_PORT` injected via docker-compose or Kubernetes pod spec.

9. Database credentials in production are managed through AWS Secrets Manager. The `terraform/db/main.tf` creates `aws_secretsmanager_secret` and `aws_secretsmanager_secret_version` resources with the generated password. When planning a new service that needs database access, plan the Secrets Manager integration: the ECS/EKS pod spec reads the secret via the `secretsmanager:GetSecretValue` IAM permission granted in `terraform/image-in-fargate/ecs.tf`. Do not hardcode passwords.

10. There is no database migration history tracking. The SQL files in `services/postgres/sql/` represent the current desired state, not a delta history. When planning schema changes, plan a new SQL file using `CREATE TABLE IF NOT EXISTS` or `ALTER TABLE` with appropriate guards. The numeric prefix (100, 200, etc.) allows inserting ordered steps between existing scripts.

### Aspect 3: Frontend-Backend Integration

11. The UI communicates with backend services exclusively through the AWS API Gateway at `api.{domain}`. Locally, this is overridden using webpack `DefinePlugin` constants: `URL_FORTUNES` and `URL_NAMES` (see `services/ui/webpack.config.js`). When planning a new service with UI integration, plan two things simultaneously: the webpack environment variable definition in `webpack.config.js` AND the corresponding API Gateway resource in the service's Terraform module. The frontend never calls services directly in production.

12. All API routes follow the path pattern `/v1/{service-name}/`. The API Gateway module in `terraform/rest_api/main.tf` creates a `v1` resource as the base path, and each service module creates its own child resource (e.g., `fortunes`, `heroes`, `names`). When planning a new API-connected service, plan the `aws_api_gateway_resource` with `parent_id = module.rest_api.version_path_id` and `path_part = var.name`.

13. All Flask services return CORS headers allowing all origins. The `after_request_func` decorator in both `heroes/src/app.py` and `names/src/app.py` sets `Access-Control-Allow-Origin: *`. The Lambda fortunes handler also returns CORS headers in its response dict. When planning any new backend service with UI integration, plan the CORS handling as a required implementation step - the UI's `useFetch` hook will fail without it.

14. The frontend uses a single custom hook `useFetch` (in `services/ui/src/hooks/useFetch.js`) as the sole method for all API calls. It manages three states: `MODE_LOADING`, `MODE_ERROR`, `MODE_SUCCESS`. When planning new UI features that call APIs, plan to use this existing `useFetch` hook rather than new fetch patterns. The hook returns `{ response, mode, error, callOnce }` - plan UI components to destructure these four values and handle all three mode states explicitly.

15. The backend services use a camelCase-to-snake_case ORM mapping dictionary for field name translation (see `HERO_ORM` in `heroes/src/app.py`). When planning a new CRUD service, plan this ORM mapping dict as a required artifact to handle the JSON API field names (camelCase from frontend) mapping to database column names (snake_case). Map it before writing SQL queries.

### Aspect 4: Testing Strategy and Timing

16. The project runs tests only on pull requests, not on push to main (see `.github/workflows/pr_qa.yml`). The PR QA workflow runs ESLint (`npm run lint`) then Jest (`npm test`) in the `services/ui` directory. When planning a feature, plan linting compliance and unit test coverage as PR-blocking gates - they must pass before merge. There is no backend Python test suite in the current codebase.

17. Frontend tests use Jest with `--coverage` flag and `@testing-library/react-hooks` for custom hook tests. The only existing test file is `services/ui/src/hooks/__tests__/useFetch.test.js`, which tests the hook in isolation using `fetch-mock` and `renderHook`. When planning new hooks, plan corresponding tests in `src/hooks/__tests__/` following the same pattern: fixtures, `beforeAll`/`afterAll` mock setup, and explicit tests for loading/success/error states.

18. The test configuration in `package.json` collects coverage from `src/**/*.{js,jsx}` excluding `src/index.js`. Asset files (images, fonts, CSS) are mocked via `src/__mocks__/fileMock.js` and `src/__mocks__/styleMock.js`. When planning new React components that import assets or stylesheets, plan for these mock files to handle the imports during test runs - no additional mock setup is needed for standard assets.

19. The `renderFortune` and `renderNames` functions in `services/ui/src/components/Fortune.js` and `Names.js` are exported as named functions specifically to enable unit testing of the render logic without mounting the full component. When planning new components that call APIs, plan to extract the render logic into a named exported function (`renderXxx`) that can be tested independently from the component's data-fetching lifecycle.

20. There are no integration tests, end-to-end tests, or API tests in the current test suite. The testing strategy is unit-only for the frontend hook layer. When planning a new feature's test strategy, plan frontend unit tests for hooks and render functions first. Do not plan integration tests unless explicitly added to the CI pipeline.

### Aspect 5: Page and Route Creation

21. The UI uses HashRouter from `react-router-dom` (not BrowserRouter). Routes are defined in `services/ui/src/App.js` using `<Switch>` and `<Route>` components. The default route (`path="/"`) renders the Fortune component; `path="/names"` renders the NamesRoute. When planning new pages, plan a new `<Route>` entry in `App.js` and a new top-level component in `services/ui/src/components/`. HashRouter means URLs use `#/route` format in the browser - plan for this in API Gateway routing (static site only serves `index.html`).

22. The navigation menu in `services/ui/src/components/Header.js` uses USWDS `ExtendedNav` with `NavDropDownButton` and `Menu` components for dropdown navigation. New pages must be added to the `primaryNavItems` array in Header.js. The `apiMap` dictionary in `Names.js` drives the dropdown items for the "Random Names" menu. When planning a new section with multiple sub-routes (like names), plan an `apiMap`-style dictionary to drive both the navigation dropdown and the route mapping.

23. All pages use the USWDS (US Web Design System) via `@trussworks/react-uswds`. Every new page must use USWDS `Grid`, `GridContainer`, and `usa-section` class patterns (see Fortune.js and Names.js for the standard layout). Plan pages as `<section className="grid-container usa-section">` containing `<Grid row gap>` with tablet column breakpoints. Do not plan custom layout components - use USWDS Grid.

24. The UI is a single-page application deployed as a static bundle to S3 and served via CloudFront. The `webpack.config.js` outputs to `dist/` directory with `index.html` as the entry point. When planning new pages, no server-side routing changes are needed - HashRouter handles all routing client-side. The only server-side change is the API Gateway routes for new backend services.

### Aspect 6: Service Integration Patterns

25. Every new backend service follows this integration chain: ECR repository (image storage) -> Docker image build -> ECS/EKS/Lambda deployment -> API Gateway resource. The `terraform/all.tf` file shows this pattern: `module.image_repo` creates the ECR repo, then `module.fortunes`/`module.heroes`/`module.names` each reference `module.image_repo[name].repo_url`. When planning a new service, plan all four Terraform resources as a sequential dependency chain.

26. Services connect to the API Gateway through one of three integration patterns, each with a dedicated Terraform module: (a) Lambda via `terraform/image-in-lambda/` using `AWS_PROXY` integration (fortunes), (b) ECS Fargate via `terraform/image-in-fargate/` using NLB + VPC Link + `HTTP_PROXY` integration (the pattern for Fargate services), (c) EKS via `terraform/image-in-eks/` using Kubernetes Deployment + Service + NLB + VPC Link (heroes, names currently use this). Choose the correct module based on the service's compute requirements.

27. The API Gateway serves as the single entry point for all backend services under `api.{domain_name}`. Route 53 routes `api.*` DNS to API Gateway. When planning a new service, it does not get its own domain - it gets a path under the existing API Gateway. Plan the `aws_api_gateway_resource` path, not a new Route 53 record.

28. Services in private VPC subnets use VPC Endpoints for AWS service access. The `terraform/vpc/vpc_endpoints.tf` creates Interface endpoints for `ecr.api`, `ecr.dkr`, `logs`, and `secretsmanager`, plus a Gateway endpoint for `s3`. When planning a service that needs additional AWS services (e.g., SQS, SNS), plan a new VPC endpoint for that service type before planning the service code that uses it.

### Aspect 7: Email and Notification Integration

29. There is no email or notification infrastructure currently in this project. No SES, SNS, or external email service is configured in `terraform/` or referenced in any service code. When planning a feature requiring email notifications, plan the following new Terraform resources first: `aws_ses_domain_identity` for email sending, and `aws_sns_topic` + `aws_sns_subscription` for event-driven notifications. Add these as a `terraform/notifications/` module following the same module pattern as `terraform/db/` with `main.tf`, `variables.tf`, `outputs.tf`.

30. If planning email functionality, the Python service layer (Flask on ECS or Lambda) would handle email by calling AWS SES via boto3. The service's IAM role (following the ECS exec role pattern in `terraform/image-in-fargate/ecs.tf`) must be updated with `ses:SendEmail` permission. Plan the IAM policy update as a separate chunk from the application code.

### Aspect 8: File Upload and Storage Integration

31. There is no file upload infrastructure currently in this project. The S3 bucket configured in `terraform/www-bucket/main.tf` is a static website bucket with public read access - it is not designed for user uploads. When planning a feature requiring file uploads, plan a new private S3 bucket (separate from the www bucket) with a different bucket policy. Do not plan to reuse the static website bucket for user content.

32. The VPC Endpoint Gateway for S3 exists in `terraform/vpc/vpc_endpoints.tf`, meaning services in private subnets can access S3 without going through the public internet. When planning a service that writes to S3 (uploads, reports, exports), plan to use this existing S3 VPC endpoint - no new networking is needed. Add `s3:PutObject` and `s3:GetObject` to the service's IAM role policy following the pattern in `terraform/image-in-fargate/ecs.tf`.

### Aspect 9: Background Job Integration

33. There are no background job, queue, or async processing systems currently in this project. No SQS, Step Functions, or scheduled Lambda (EventBridge) configurations exist in `terraform/`. The Lambda pattern (fortunes) is currently used only for synchronous HTTP request/response. When planning a background job feature, the Lambda model is the closest existing pattern - plan to add an `aws_cloudwatch_event_rule` (EventBridge) trigger to an existing or new Lambda function rather than adding a separate job framework.

34. The fortunes Lambda function in `services/fortunes/src/app.py` uses the `root_handler(event, context)` function signature required by AWS Lambda. The `CMD [ "app.root_handler" ]` in the Dockerfile specifies the handler. When planning an async processing Lambda, follow this exact same pattern: single handler function, Dockerfile CMD pointing to `file.handler_name`.

### Aspect 10: Caching Strategy Integration

35. The only caching in this project is CloudFront for the static website. The `terraform/static-web/cloudfront.tf` configures `default_ttl = 86400` (24 hours) and `max_ttl = 31536000` (1 year) for static assets. CloudFront cache invalidation is handled in the `deploy_ui.yml` GitHub Actions workflow via `aws cloudfront create-invalidation --paths '/*'`. When planning static frontend changes, plan the CloudFront invalidation step as a required deployment artifact.

36. The API services (heroes, names, fortunes) have no application-level caching. All requests go directly to the service logic - fortunes picks from a hardcoded list, names reads from text files on each request, heroes queries the database on each request. When planning a new high-traffic API feature, plan an API Gateway cache stage setting or an ElastiCache resource as an optional performance chunk, not as a default.

### Aspect 11: Security and Permissions Planning

37. IAM permissions follow the principle of least privilege but are implemented at the service level, not the user level. Each ECS task has two IAM roles: a `task_role` (what the app can do) and an `exec_role` (what ECS can do to run the container, including ECR pull and CloudWatch log writes). See `terraform/image-in-fargate/ecs.tf`. When planning a new service, plan both IAM roles as required infrastructure. The exec role permissions are standard (`ecr:*`, `logs:*`, `secretsmanager:GetSecretValue`); the task role gets only what the application specifically needs.

38. Lambda functions use a single IAM role with `sts:AssumeRole` for `lambda.amazonaws.com`. See `terraform/image-in-lambda/lambda_fn.tf`. The current Lambda role has no additional permissions beyond the basic trust policy. When planning a Lambda feature that calls AWS services, plan to add an `aws_iam_role_policy` resource to the Lambda module with the specific permissions needed.

39. Database security uses a VPC security group with two ingress rules: developer CIDR blocks (individual developer IPs from `terraform.tfvars` `developer_cidr_blocks`) and VPC private subnet CIDR blocks. See `terraform/db/main.tf`. When planning a new service that needs database access, verify it runs in the VPC private subnets - it will automatically have database access. External access requires adding developer IPs to `terraform.tfvars`.

40. API Gateway uses `authorization = "NONE"` for all methods (see `terraform/image-in-lambda/api_gateway.tf` and `terraform/image-in-eks/api_gateway.tf`). There is no authentication or authorization currently implemented. When planning a feature requiring protected endpoints, plan to add an API Gateway authorizer resource as a new Terraform component - this is a significant infrastructure change that should be its own feature chunk.

41. ECR repositories have a policy allowing `*` principal access (see `terraform/ecr/main.tf`). Image scanning on push (`scan_on_push = true`) is enabled. When planning a new service deployment, the ECR repository policy is already permissive enough for CI/CD - no additional ECR IAM changes needed for the GitHub Actions deployment workflows.

### Aspect 12: Configuration and Environment Planning

42. Service configuration is injected exclusively via environment variables. The heroes service reads `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_HOST`, `POSTGRES_PORT` with sensible defaults (see `heroes/src/app.py`). Locally these come from `docker-compose.yml`; in production from Kubernetes pod `env` specs or ECS task definition `environment` and `secrets` arrays. When planning a new service, plan the full list of environment variables at the start, with both local `docker-compose.yml` and production Terraform pod spec as two separate implementation artifacts.

43. The terraform.tfvars file contains the project-wide variables: `account_id`, `region`, `name` (project name "HOOP"), `domain_name`, and `developer_cidr_blocks`. These are the only project-wide configuration values. When planning infrastructure for a new service, use `var.name` and `var.region` from these shared variables - do not hardcode AWS account IDs or region strings in new Terraform modules.

44. Frontend service URLs are injected at webpack build time using `webpack.DefinePlugin` constants (see `webpack.config.js`). The constants `URL_FORTUNES` and `URL_NAMES` default to production URLs but can be overridden with environment variables for local development. When planning a new frontend-connected service, plan a new `URL_{SERVICE}` constant in webpack.config.js with the production API Gateway URL as the default value. Document the local override in `services/Front_End_Development.md`.

45. AWS credentials are stored as GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) and Terraform Cloud API token (`TF_API_TOKEN`). Local development uses AWS credentials from the developer's local config. When planning a new service deployment workflow, do not plan new secret types - reuse the existing `secrets.AWS_ACCESS_KEY_ID` and `secrets.AWS_SECRET_ACCESS_KEY` in new GitHub Actions workflow files following the exact pattern from `deploy_heroes.yml`.

### Aspect 13: Documentation Requirements

46. Each role has a dedicated markdown guide in `services/`: `API_Development.md`, `Front_End_Development.md`, `Database_Development.md`. When adding a new service, update `API_Development.md` with the new service name, deployment target (Lambda/ECS/EKS), and brief description following the existing pattern (service path, tech, purpose, deployment target). This is a required documentation chunk for every new service.

47. Infrastructure documentation lives in `terraform/README.md` and covers the multi-step Terraform apply process. When planning infrastructure changes, plan a README.md update step that documents any new ordering requirements in the `terraform apply` sequence. The current process requires specific `-target` ordering; new services may alter this sequence.

48. Architecture diagrams use Graphviz (`.gv` files) in `docs/`. The `docs/aws_arch.gv` file shows the full service topology. When planning a new service, plan to update `docs/aws_arch.gv` to add the new service node and its connections (to API Gateway, ECR, VPC, RDS if applicable). Regenerate the PNG via `dot -Tpng -O aws_arch.gv` as documented in `docs/README.MD`.

49. The main `README.md` at the project root maintains the repository hierarchy description and links to all four role-specific guides. When adding a new service type that creates a new developer role or sub-team, add a link to its guide in the "Running Code" section of `README.md`.

### Aspect 14: Deployment and Release Planning

50. Deployment for each service is a separate, independent GitHub Actions workflow triggered manually (`on: workflow_dispatch`). There is no coordinated multi-service deployment. The workflows for heroes (`deploy_heroes.yml`), names (`deploy_names.yml`), and fortunes (`deploy_fortunes.yml`) all follow the same structure: checkout, configure AWS credentials, login to ECR, set up Docker Buildx with layer caching, prepare image tags, build and push to ECR. When planning a new service, plan a new `deploy_{service}.yml` workflow file following this exact template.

51. Docker images are tagged with both the short git SHA (`head -c7`) and `latest`. ECR image mutability is `MUTABLE` (see `terraform/ecr/main.tf`), meaning `latest` is always overwritten on each deploy. When planning a service deployment, the `:latest` tag is what Terraform and Kubernetes use to pull images. Plan to always push both the SHA tag and the latest tag in the build workflow.

52. The UI deployment (`deploy_ui.yml`) follows a different pattern: it reads Terraform outputs to get the S3 bucket name, builds the webpack bundle, syncs to S3, then invalidates CloudFront. This is a two-phase deploy: infrastructure state read (Terraform) followed by artifact deploy (S3 sync). When planning UI deployment changes, plan both phases - the Terraform output step and the S3/CloudFront steps are sequential dependencies.

53. Terraform state is stored in an S3 backend (`hoop-terraform` bucket, `dev/terraform.tfstate` key, `us-east-1` region). See `terraform/all.tf` backend configuration. Initial infrastructure provisioning requires a two-phase `terraform apply`: first `terraform apply -target=module.image_repo` and `terraform apply -target=module.www_buckets`, then image pushes via GitHub Actions, then final `terraform apply`. When planning infrastructure for new services, plan this same two-phase apply sequence as a required deployment step.

54. Lambda function updates use the `appleboy/lambda-action` GitHub Action (see `deploy_fortunes.yml`) which updates the function's image URI and publishes a new version. The `continue-on-error: true` flag on the Lambda update step means deployment failures don't block the workflow. When planning Lambda service updates, plan the `function_name` to match the `${var.name}_container` pattern set in `terraform/image-in-lambda/lambda_fn.tf`.

### Aspect 15: Rollback and Recovery Planning

55. There is no explicit rollback mechanism in the current deployment pipeline. The deploy workflows use `workflow_dispatch` (manual trigger only) and push `latest` as a mutable tag. Rollback requires re-running the deploy workflow with a previous commit checked out, which re-pushes the old image as `latest`. When planning a new service, consider whether `continue-on-error: true` is needed on the final deployment step (as done in `deploy_fortunes.yml`) to prevent the image-already-pushed from creating a stuck state.

56. The RDS database has `skip_final_snapshot = true` in `terraform/db/main.tf`. This means destroying the RDS instance via Terraform deletes all data without a final snapshot. When planning database schema changes, plan a manual RDS snapshot step before any `terraform apply` that modifies the database module, since there is no automatic safety net.

57. CloudFront distributions allow cache invalidation via `aws cloudfront create-invalidation` (used in `deploy_ui.yml`). Rolling back a UI deployment requires re-deploying the previous version to S3 and invalidating the cache. There is no CDN-level version pinning. When planning UI rollback, plan to keep the previous build artifacts accessible.

### Aspect 16: Performance Considerations

58. ECS Fargate and EKS services are configured with `desired_count = 1` / `replicas = 1` in `terraform/image-in-fargate/ecs.tf` and `terraform/image-in-eks/pod.tf`. The EKS node group has `desired_capacity = 1, max_capacity = 3` for auto-scaling. When planning a new service that must handle production load, plan to increase replicas and configure horizontal pod autoscaling as an infrastructure chunk separate from the service code chunk.

59. Flask services in this project run with `app.debug = True` and bind to `0.0.0.0` (see `heroes/src/app.py` and `names/src/app.py` main blocks). The comment in the code explicitly warns "This line should be removed before deploying a production app." When planning a new Flask service for production, plan a separate production configuration chunk that removes debug mode, uses a production WSGI server (gunicorn), and sets proper host binding.

60. The names service reads word list text files on every request using Python file I/O (see `names/src/app.py`). When planning similar static-data services, consider planning in-memory caching (Python dict or `@functools.lru_cache`) as a performance chunk, since the data never changes but file reads happen on every API call.

61. CloudFront is configured with `default_ttl = 86400` and `max_ttl = 31536000` for static assets. The Lambda integration has no caching configured at the API Gateway level. When planning a new high-read API service, plan an API Gateway cache stage as an optional performance chunk with appropriate TTL values, particularly for read-heavy endpoints that rarely change (like the names/fortunes pattern).

### Aspect 17: Monitoring and Observability

62. ECS Fargate services use CloudWatch Logs with log group `/ecs/{name}-service`, 30-day retention, and log stream prefix `ecs`. See `terraform/image-in-fargate/ecs.tf` `logConfiguration`. When planning a new ECS Fargate service, plan the CloudWatch log group resource with `aws_cloudwatch_log_group` and the same 30-day retention policy as a required Terraform resource in the service's module.

63. The RDS instance has `enabled_cloudwatch_logs_exports = ["postgresql"]` and `performance_insights_enabled = true` configured in `terraform/db/main.tf`. Database performance is observable via CloudWatch and RDS Performance Insights out of the box. When planning database-connected features, no additional monitoring infrastructure is needed for database-level observability.

64. The EKS cluster has `cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]` enabled (see `terraform/all.tf`). All cluster control plane logs go to CloudWatch. When planning EKS-deployed services, plan application-level logging to stdout/stderr so Kubernetes captures logs to CloudWatch via the node's log driver - no sidecar logging containers are needed.

65. There are no application-level metrics, distributed tracing (X-Ray), or alerting (CloudWatch Alarms, SNS alerts) configured in the current project. Observability is limited to logs. When planning a new service in production, plan a CloudWatch Alarm on Lambda error rates (for Lambda services) or ECS service health check failures (for ECS services) as a recommended but not currently standard infrastructure chunk.

66. The architecture diagram (`docs/aws_arch.gv`) shows VPC Endpoints for CloudWatch (`VPC_Endpoint_CloudWatch`) in the private subnets. This means ECS/EKS services in private subnets send logs directly to CloudWatch without internet access. When planning a new private-subnet service, log shipping to CloudWatch is already routed correctly via the VPC endpoint - no additional networking configuration is needed for logging.

67. ECR has `scan_on_push = true` configured (see `terraform/ecr/main.tf`). Container image vulnerability scanning runs automatically on every image push to ECR. When planning a new service deployment, the ECR scan provides security observability for container images. Plan to review ECR scan findings after initial image pushes as part of the deployment validation step.
