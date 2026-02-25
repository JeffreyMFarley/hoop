# Backend Agent Implementation Rules

**IMPORTANT:** These rules are for Backend Execute Agents working on specific chunks from a feature plan. For new features or complex changes, use the Plan Agent first.

## Per-File Implementation Loop

For EACH individual file, follow this exact sequence:

### Step 1: Pattern Check
- Review the pattern rules in backend-agent.md for this file type
- Identify which specific rules apply to this file

### Step 2: Similar Files Analysis
- Find 3-5 existing files of the same type in the project
- Study their structure, naming, and implementation patterns
- Note the exact conventions they follow
- **NEVER assume modules/endpoints exist - always verify exact names and paths**

### Step 3: Implement File
- **Check that all imports/modules you want to use actually exist first**
- Create the single file following the patterns discovered
- Use the exact naming, structure, and style from similar files
- **Verify module names and import paths before using them**

### Step 4: Verify Pattern Match
- Compare the new file against the pattern rules in backend-agent.md
- Ensure it follows the same conventions as existing similar files
- **Verify file is in the correct folder** following project structure
- **Verify all imports are correct** and follow project import patterns
- Fix any deviations immediately

### Step 5: Verify Types
- **Use VSCode MCP server getDiagnostics if available** for efficient type checking
- If MCP not available, check that types compile correctly
- Ensure TypeScript (if used) passes for this file
- Fix any type errors

### Step 6: Write Test (MANDATORY if project has tests)
- **NEVER skip this step** - always check if similar files have tests
- If project has tests for similar files, **YOU MUST write test for this file**
- Follow the same testing patterns used in the project
- **Run the test for THIS FILE ONLY** to verify it passes

### Step 7: Final Validation, Verification and Documentation
- **Use VSCode MCP server getDiagnostics if available** for final type/lint checking
- **Run linting tools on this single file** - must pass
- **Run type checking on this single file** - must pass
- Verify the file integrates with existing code
- **If feature requires permissions:** Check if existing permission applies or ask user if new permission needed
- **Verify pattern compliance:** Confirm this file follows ALL applicable pattern rules
- **Verify requirements:** Confirm this file meets the original feature requirements
- **Document the feature:** Create/update documentation following project documentation patterns
- **ONLY IF ALL CHECKS PASS:** Mark this file as truly complete

## CRITICAL: ONE FILE AT A TIME ONLY
- **NEVER create multiple files in one response**
- **NEVER say "Now let me create the next file"**
- **COMPLETE ALL 7 STEPS for the current file BEFORE even mentioning another file**
- **MUST run lint and type check on THIS FILE before moving on**
- **MUST run any tests written for THIS FILE before moving on**
- Each file must go through: pattern check → analysis → implement → verify → types → test → final validation & documentation
- Only after all 7 steps pass completely should you consider the next file

---

## Backend Patterns - hoop

### Project Overview

This is an AWS-native scaffolding project demonstrating multiple deployment patterns for Python microservices. It contains three API services (heroes, names, fortunes), a PostgreSQL database, and infrastructure-as-code via Terraform. Services are deployed to ECS Fargate, EKS, and AWS Lambda depending on the service.

---

## Aspect 1: API Endpoint Structure and Conventions

1. **Flask is the web framework for all HTTP services.** Every Flask service app file is located at `services/<service-name>/src/app.py` and creates its Flask app with `app = Flask(__name__)`. See `services/heroes/src/app.py` and `services/names/src/app.py`.

2. **All routes use lowercase, hyphen-free, single-word path segments.** Examples from this codebase: `/`, `/<int:id>`, `/brute`, `/easy`, `/name`, `/star`, `/noun`, `/verb`. No camelCase or kebab-case paths exist in the Python services.

3. **The root route `/` always returns a collection.** In heroes it returns all applicant rows. In names it returns a list of available sub-route URLs (`[request.base_url + x for x in TABLE.keys()]`). Every service defines a root `@app.route('/')` GET handler.

4. **Resource-by-ID uses `/<int:id>` path parameter with typed int conversion.** The heroes service uses `@app.route('/<int:id>')` with the function signature `def get(id):`. Do not use string IDs or UUIDs in path parameters.

5. **HTTP method separation is explicit per route decorator.** POST and GET for the same path are defined as separate functions: `@app.route('/', methods=['POST'])` with `def add_new():` is a separate function from `@app.route('/')` with `def index():`. Never use `methods=['GET', 'POST']` on the same function.

6. **Lambda functions (fortunes) use a single handler function, not Flask.** The fortunes service at `services/fortunes/src/app.py` defines `def root_handler(event, context):` returning a dict with `statusCode`, `headers`, and `body`. This is the AWS Lambda handler pattern used for serverless services. Flask is only for container-based services.

---

## Aspect 2: Request and Response Patterns

7. **JSON responses use `jsonify()` from Flask.** All GET responses return `jsonify(data_rows)` or `jsonify(dict(zip(fields, record)))` or `jsonify(list(...))`. Never return raw dicts or use `json.dumps()` in Flask route handlers.

8. **POST responses for resource creation return 201 with a Location header.** The heroes `add_new()` function builds a URI as `f'{request.base_url}{id}'`, creates `resp = Response(uri, 201)`, sets `resp.location = uri`, and returns `resp`. Do not use `jsonify()` for 201 created responses - use `Response()` directly.

9. **Content-type negotiation on POST bodies supports both form-urlencoded and JSON.** The heroes service checks `request.content_type == 'application/x-www-form-urlencoded'` and uses `request.form.to_dict(flat=True)`, or falls back to `json.loads(request.data)` for JSON. If neither, returns `f'Unrecognized Content Type {request.content_type}', 400`.

10. **Lambda function responses always include CORS headers in the return dict.** The fortunes handler returns: `'Access-Control-Allow-Headers': 'Content-Type'`, `'Access-Control-Allow-Origin': '*'`, `'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'`. The body is `json.dumps({...})` as a string, not a dict.

11. **Simple string error messages are returned directly as tuples.** Error responses use the pattern `return f'Unknown hero', 404` or `return f'Unrecognized Content Type {request.content_type}', 400`. No JSON error body structure is used.

---

## Aspect 3: Authentication and Authorization

12. **This project has NO authentication or authorization on any API endpoint.** All API Gateway methods use `authorization = "NONE"`. All Flask routes have no auth decorators. All Lambda functions have no auth checks. This is a scaffolding/demo project - when adding a new service, do not add auth unless explicitly required.

13. **CORS is handled at the Flask application level via `@app.after_request`.** Both `heroes` and `names` services define an identical `after_request_func` that sets `response.access_control_allow_headers`, `response.access_control_allow_origin = '*'`, and `response.access_control_allow_methods`. This is application-wide, not per-route.

    ```python
    @app.after_request
    def after_request_func(response):
        response.access_control_allow_headers = ['Content-Type']
        response.access_control_allow_origin = '*'
        response.access_control_allow_methods = ['OPTIONS','POST','GET']
        return response
    ```

---

## Aspect 4: Database Access Patterns

14. **Database connections are created per-request via a `connection()` function, not a connection pool.** The heroes service defines a module-level `connection()` function that reads environment variables and calls `psycopg2.connect()` with a DSN string format: `"host={0} dbname={1} user={2} password={3} port={4}"`. There is no connection pooling or ORM.

15. **Database operations use `with connection() as conn:` and `with conn.cursor() as cursor:` context managers.** All DB code in heroes follows this exact nesting pattern. The `with` statement on psycopg2 connections handles transaction commits/rollbacks automatically.

16. **SELECT queries use `cursor.description` to extract field names dynamically.** The pattern is: `fields = [desc[0] for desc in cursor.description]`, then rows are converted with `dict(zip(fields, row))`. Never hardcode column names in result mapping.

17. **INSERT queries use named parameter placeholders with `%(name)s` syntax.** The heroes service builds SQL using: `', '.join(['%({0})s'.format(x) for x in HERO_ORM])` to generate placeholders. The body dict is passed directly to `cursor.execute(sql, body)`. Use `RETURNING ID;` to get the new row's ID.

18. **Field name mapping between API (camelCase) and DB (snake_case) uses a module-level dict called `HERO_ORM`.** The mapping is defined at the top of `app.py` as a constant dict: `HERO_ORM = {'countryOfBirth': 'country_of_birth', ...}`. Use `HERO_ORM.values()` for column names in SQL and `HERO_ORM` keys for input validation.

19. **Null checks for missing records use `if record is None: return f'...', 404`.** After `cursor.fetchone()`, check if the result is None and return a 404 string response. See `services/heroes/src/app.py` lines 103-104.

---

## Aspect 5: Data Models and Schema Design

20. **Tables use `BIGSERIAL` as the primary key type, not `SERIAL` or `UUID`.** The applicant table uses `id BIGSERIAL` without a PRIMARY KEY constraint in the CREATE TABLE statement (see `services/postgres/sql/100_CREATE_applicant.sql`).

21. **All tables are created in the `public` schema explicitly.** The SQL uses `CREATE TABLE IF NOT EXISTS public.applicant (...)`. Always specify the `public.` schema prefix on table creation.

22. **String columns use `character varying(255)` not `VARCHAR(255)` or `TEXT`.** The applicant table consistently uses `character varying(255) not null` for all name fields. Date fields use the `date` type.

23. **`CREATE TABLE IF NOT EXISTS` is always used** to make schema scripts idempotent. Never use bare `CREATE TABLE`.

---

## Aspect 6: Migration and Schema Management

24. **Schema scripts are plain SQL files stored in `services/postgres/sql/` with numeric prefixes for ordering.** The only script is `100_CREATE_applicant.sql`. Use 3-digit numeric prefixes (100, 200, etc.) with the pattern `{number}_{VERB}_{table_name}.sql` in ALL CAPS for the verb and table name.

25. **The local postgres service applies migrations automatically via Docker.** `services/postgres/Dockerfile` copies `./sql` into `/docker-entrypoint-initdb.d/`. Scripts in that directory are executed in alphabetical/numeric order on container first start. There is no migration tool (no Flyway, Alembic, Liquibase).

26. **There is no production migration mechanism defined in the codebase.** The RDS instance in Terraform (`terraform/db/main.tf`) is created empty. Schema must be applied manually or via a separate process to production. Do not expect automatic migrations in production.

---

## Aspect 7: Error Handling and HTTP Status Codes

27. **404 responses use a plain string message, not JSON.** `return f'Unknown hero', 404` is the pattern. No error envelope structure is used.

28. **400 responses for bad content types use a plain f-string.** `return f'Unrecognized Content Type {request.content_type}', 400`. No standardized error format exists in the codebase.

29. **No global error handler (`@app.errorhandler`) is defined in any service.** Flask's default error behavior is used. Do not add a custom error handler unless the feature specifically requires it.

30. **Lambda functions always return statusCode 200** in the existing code. The fortunes handler has no error path - it always returns 200 with a random fortune. Error handling is minimal.

---

## Aspect 8: Input Validation and Sanitization

31. **Input validation is minimal - the project uses parameterized queries as the only protection.** The heroes service passes the request body dict directly to `cursor.execute(sql, body)` using psycopg2's parameterized query mechanism. There is no schema validation library (no Marshmallow, Pydantic, Cerberus).

32. **The `HERO_ORM` dict serves as an implicit field whitelist.** By constructing SQL from `HERO_ORM.values()` and `HERO_ORM` keys, only known fields are used in INSERT statements. Unknown fields in the body are ignored because the SQL is built from the ORM dict, not from user input.

33. **No input sanitization, length checking, or type validation is performed in Python code.** The database constraints (e.g., `not null`, `character varying(255)`) are relied upon to reject invalid data. Database errors are not caught and will bubble up as 500 errors.

---

## Aspect 9: Service Architecture and Organization

34. **Each microservice is a standalone Python Flask or Lambda app in its own directory under `services/`.** The structure is `services/<service-name>/src/app.py` for the application code. There is no shared library, common module, or framework shared across services.

35. **Services are single-file applications.** Each service has exactly one Python source file (`app.py`) in `services/<service-name>/src/`. No service has multiple Python modules, blueprints, or sub-packages.

36. **Data files co-located with the app in `src/`.** The names service stores word list text files (`.txt`) in `services/names/src/` alongside `app.py`. File paths are computed relative to the module using `thisDir = os.path.dirname(__file__)`.

37. **Three deployment patterns exist, each as a separate module type in terraform.** Container in Lambda uses `image-in-lambda`, container in EKS uses `image-in-eks`, container in Fargate uses `image-in-fargate`. The choice of deployment pattern determines which Terraform module to use when adding a new service.

38. **Static data used by a service (word lists, lookup tables) is loaded at request time, not cached at startup.** The names service calls `load(to_absolute(fileName))` inside each route handler, reading the file on every request. There is no module-level caching of file contents.

---

## Aspect 10: Configuration and Environment Management

39. **All configuration comes from environment variables with safe defaults.** The connection function uses `os.getenv('POSTGRES_USER', 'postgres')` for every value. Default values are set so the app can run with minimal configuration for local development.

40. **Environment variable names for database connectivity are standardized across all services.** The five DB env vars used consistently are: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_HOST`, `POSTGRES_PORT`. All services and Terraform modules use these exact names.

41. **Local development uses `docker-compose.yml` to inject environment variables.** The `services/docker-compose.yml` sets `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_HOST` directly under the `environment:` key of each service. No `.env` file is used.

42. **The `docker-compose.yml` uses volume mounts for hot-reload during development.** Both heroes and names mount their `src/app.py` directly: `./heroes/src/app.py:/home/app/app.py`. This allows editing the Python source without rebuilding the container.

43. **Terraform variables are declared with `type`, `description`, and optional `default`.** Every variable in every `variables.tf` follows this pattern. Sensitive defaults (passwords) are generated by `random_string` resource, not hardcoded. See `terraform/db/main.tf`.

44. **`terraform.tfvars` stores project-level values but NOT secrets.** It contains `account_id`, `region`, `name`, `domain_name`, `developer_cidr_blocks`. The database password is generated by Terraform's `random_string` resource and stored in AWS Secrets Manager, never in tfvars.

---

## Aspect 11: Logging and Observability

45. **ECS Fargate services send logs to CloudWatch using the `awslogs` log driver.** The Fargate task definition in `terraform/image-in-fargate/ecs.tf` configures: `logDriver: "awslogs"` with options `awslogs-group: "/ecs/${var.name}-service"`, `awslogs-region: var.region`, `awslogs-stream-prefix: "ecs"`. Log group retention is 30 days.

46. **CloudWatch log groups are named `/ecs/<service-name>-service`.** See `aws_cloudwatch_log_group.main` in `terraform/image-in-fargate/ecs.tf`: `name = "/ecs/${var.name}-service"`.

47. **API Gateway has metrics enabled at the stage level.** The `terraform/rest_api/stage.tf` creates `aws_api_gateway_method_settings` with `metrics_enabled = true` for the `*/*` method path.

48. **RDS has Performance Insights and CloudWatch PostgreSQL logs enabled.** The DB module enables `performance_insights_enabled = true` and `enabled_cloudwatch_logs_exports = ["postgresql"]` on the `aws_db_instance`.

49. **No application-level logging (Python `logging` module) is present in the Flask services.** Services rely entirely on stdout/stderr captured by the container runtime. Do not add structured logging unless explicitly required.

---

## Aspect 12: Testing Patterns and Conventions

50. **There are NO backend tests in this project.** No test files, no test directories, no test frameworks (pytest, unittest) are present in any service directory. The CI workflow `pr_qa.yml` only runs frontend tests (npm test for the UI service).

51. **When adding a new service, no test is required by the project convention.** However, follow the instruction in Step 6 of the per-file loop: check if tests exist for similar files. Since none exist, you may skip writing tests for Python services unless the user explicitly requests it.

---

## Aspect 13: Docker and Containerization Patterns

52. **All Dockerfiles use 3-stage builds: base image, build image, final runtime image.** The stages are labeled `python-alpine` (or `python-base`), `build-image`, and the final unnamed stage. Use `COPY --from=build-image` to copy the built artifacts into the lean final image.

53. **Python version is defined as a global ARG at the top of each Dockerfile: `ARG RUNTIME_VERSION="3.9"`.** The distro version for Alpine images is `ARG DISTRO_VERSION="3.12"`. Dependencies are installed with `python${RUNTIME_VERSION} -m pip install -r /requirements.txt --target ${FUNCTION_DIR}`.

54. **The function directory inside the container is always `/home/app/` and is set via ARG.** `ARG FUNCTION_DIR="/home/app/"` is declared at the top of every Dockerfile. `WORKDIR ${FUNCTION_DIR}` is set in the final stage.

55. **Source files are copied from `src/*` into the function directory.** The pattern is `COPY src/* ${FUNCTION_DIR}`. All Python source and supporting data files in `src/` land directly in `/home/app/`.

56. **Flask services use Alpine-based images; heroes service uses Buster (Debian-slim).** Names and fortunes use `python:${RUNTIME_VERSION}-alpine${DISTRO_VERSION}`, which requires `apk add`. Heroes uses `python:${RUNTIME_VERSION}-slim-buster` and `apt-get install`. Match the base image to the service's dependency needs.

57. **The entrypoint is always `/entry.sh`, copied in and made executable with `chmod 755`.** Flask services have `entry.sh` containing simply `python app.py`. Lambda services have a conditional that checks `AWS_LAMBDA_RUNTIME_API` to decide between the Lambda RIE and the actual runtime.

58. **Lambda images install `awslambdaric` (AWS Lambda Runtime Interface Client) via pip.** The CMD for Lambda containers is `["app.root_handler"]` - the module name dot the handler function name.

59. **docker-compose ports map host ports that differ per service:** fortunes: `9000:8080`, heroes: `5050:5000`, names: `5000:5000`. The host port for heroes differs from the container port to avoid conflicts.

60. **No `CMD` instruction in Flask service Dockerfiles.** The entrypoint shell script handles startup. Lambda Dockerfiles have `CMD ["app.root_handler"]` to specify the handler.

---

## Aspect 14: CI/CD Pipeline Patterns

61. **Each service has its own GitHub Actions workflow file for deployment.** Files are named `deploy_<service>.yml` (e.g., `deploy_heroes.yml`, `deploy_names.yml`, `deploy_fortunes.yml`). Deployment workflows are triggered by `workflow_dispatch` (manual trigger), NOT on push to main.

62. **All deployment workflows share an identical first section: checkout, configure AWS credentials, ECR login, Docker Buildx setup, and layer caching.** The cache path is `/tmp/.buildx-cache` with key `${{ runner.os }}-buildx-${{ github.sha }}`. After push, the cache is renamed from `buildx-cache-new` to `buildx-cache`.

63. **Image tags use two formats: short SHA and `latest`.** The prepare step uses `TAG=$(echo $GITHUB_SHA | head -c7)` and creates both `${REGISTRY}/${REPO}:${TAG}` and `${REGISTRY}/${REPO}:latest`. Both are pushed simultaneously.

64. **Service-specific configuration is set as workflow-level `env:` variables.** Each deploy workflow defines `REGION`, `REPO`, and `SRC_DIR` (and for Lambda: `FUNCTION_NAME`) at the job level. Use these env vars throughout the workflow steps rather than hardcoding.

65. **Lambda deployments add a post-push step to update the function.** The fortunes deploy workflow uses `appleboy/lambda-action@master` with `image_uri` pointing to the `latest` tag and `publish: true`. This step has `continue-on-error: true` since the function may not exist yet.

66. **PR quality checks run on the `pull_request` event and only test the UI.** The `pr_qa.yml` workflow runs `npm run lint` and `npm test` in the `./services/ui` directory. No backend linting or testing occurs on PRs.

67. **Website deployment integrates Terraform outputs to get the S3 bucket name.** The `deploy_ui.yml` workflow runs `terraform init` and `terraform output static_web_bucket` to get the bucket, then uses `aws s3 sync` to deploy. CloudFront cache is invalidated with `aws cloudfront create-invalidation`.

68. **AWS credentials are injected from GitHub Secrets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.** All workflows reference `${{ secrets.AWS_ACCESS_KEY_ID }}` and `${{ secrets.AWS_SECRET_ACCESS_KEY }}`. Terraform Cloud token is `${{ secrets.TF_API_TOKEN }}`.

---

## Aspect 15: Infrastructure as Code Patterns (Terraform)

69. **All Terraform is organized into reusable modules inside `terraform/` subdirectories.** Module directories are: `db/`, `ecr/`, `ecs-cluster/`, `image-in-eks/`, `image-in-fargate/`, `image-in-lambda/`, `rest_api/`, `static-web/`, `vpc/`, `www-bucket/`. The root `all.tf` composes them.

70. **Every Terraform module has exactly three files: `main.tf`, `variables.tf`, `outputs.tf`.** Some modules split resources into multiple files (e.g., `api_gateway.tf`, `pod.tf`, `route_53.tf`, `stage.tf`), but always have these three core files. Resource files are named by concern.

71. **Module inputs and outputs are consistently described using `description` fields.** Every `variable` block has `type`, `description`, and optionally `default`. Every `output` block has `value` and optionally `description`. This is not optional - all blocks must be documented.

72. **The project uses `for_each = toset([...])` to create multiple similar resources.** ECR repos are created with `for_each = toset(["fortunes", "heroes", "names"])` and accessed as `module.image_repo["fortunes"]`. S3 buckets use the same pattern.

73. **Terraform backend state is stored in S3 at `hoop-terraform` bucket, key `dev/terraform.tfstate`, region `us-east-1`.** This is defined in `terraform/all.tf`. When creating a new project from this scaffolding, update the bucket name.

74. **The AWS provider is configured in `terraform/provider.tf` with `default_tags`.** The `default_tags` block applies `Name = var.name` to all resources. Do not add tags at the resource level unless they differ from the default.

75. **Services are connected to API Gateway at path `/v1/<service-name>`.** The `rest_api` module creates a `/v1` resource. Each service module receives `parent_id = module.rest_api.version_path_id` and creates its own path resource with `path_part = var.name`. All APIs are versioned under `/v1/`.

76. **API Gateway uses `http_method = "ANY"` with `{proxy+}` child resources for EKS/Fargate services.** This means the API Gateway acts as a transparent proxy, forwarding any HTTP method and any sub-path to the backend. Lambda services use a single `ANY` method without proxy.

77. **Secrets are stored in AWS Secrets Manager with `recovery_window_in_days = 0`.** The DB password secret is created with this setting for immediate deletion (useful in dev). The secret is named `${var.name}-db-password`.

78. **Resource naming convention is `${var.name}-<resource-type>` in lowercase.** Examples: `"${var.name}-db-sg"` for security groups, `"nlb-${var.name}"` for load balancers, `"ecs-task-role-${var.name}"` for IAM roles, `"ecs-service-${var.name}"` for task family names.

---

## Aspect 16: Secret and Credential Management

79. **Database passwords are auto-generated by Terraform using `random_string` with `special = false`, length 16.** The resource is `resource "random_string" "db_password"` in `terraform/db/main.tf`. Never hardcode passwords in Terraform. The result is stored in AWS Secrets Manager.

80. **Production database credentials are passed to EKS pods as plain environment variables in the pod spec.** The `terraform/image-in-eks/pod.tf` injects `POSTGRES_USER`, `POSTGRES_DB`, `POSTGRES_HOST`, `POSTGRES_PASSWORD` as plain env vars. There is commented-out code for using the AWS Secrets Sidecar Injector (the annotation block is present but disabled).

81. **Local development uses hardcoded credentials in `docker-compose.yml`.** `POSTGRES_PASSWORD: foobar` is directly in `services/docker-compose.yml`. This is intentional for local dev convenience.

82. **Fargate task definitions support secrets via the `secrets` variable** (`type = list`, default `[]`). Secrets are `{name: x, valueFrom: arn}` items sourced from Secrets Manager. The exec role grants `secretsmanager:GetSecretValue`. This is the production pattern for sensitive values in Fargate.

---

## Aspect 17: Performance and Scaling Patterns

83. **EKS deployments default to 1 replica.** The `kubernetes_deployment` in `terraform/image-in-eks/pod.tf` sets `replicas = 1`. EKS node groups have `desired_capacity = 1`, `max_capacity = 3`, `min_capacity = 1` with `t3.large` instance types.

84. **Fargate services run with 1 desired count, 1024 CPU units, 2048 MB memory by default.** See `terraform/image-in-fargate/variables.tf`: `cpu = 1024`, `memory = 2048`, `desired_count = 1`.

85. **CloudFront caches static assets with `default_ttl = 86400` (1 day) and `max_ttl = 31536000` (1 year).** Compression is enabled (`compress = true`). Only GET and HEAD methods are allowed and cached for the static site.

86. **VPC Endpoints are used to keep ECR, CloudWatch, Secrets Manager, and S3 traffic private.** The `terraform/vpc/vpc_endpoints.tf` creates Interface endpoints for `ecr.api`, `ecr.dkr`, `logs`, `secretsmanager` and a Gateway endpoint for S3. This avoids NAT Gateway charges for AWS service traffic from private subnets.

87. **There is no application-level caching (Redis, Memcached, or in-memory).** The project has no caching layer. Each request hits the database or file system directly. Do not add caching infrastructure without explicit requirement.

---

## Aspect 18: Background Job Patterns

88. **This project has NO background job infrastructure.** No Celery, no SQS consumers, no scheduled tasks (EventBridge, CloudWatch Events). The three services are purely synchronous HTTP request/response. Do not add background job patterns without explicit architectural guidance.

---

## Aspect 19: File Storage Patterns

89. **S3 is used only for static website hosting, not for application file uploads.** The `www-bucket` module creates an S3 bucket with `acl = "public-read"` and a static website configuration (`index_document = "index.html"`). There is no application-level file upload endpoint.

90. **The word list text files in names service are stored in the container image, not S3.** Files in `services/names/src/` (brutethink.txt, easy-names.txt, etc.) are copied into the container at build time via `COPY src/* ${FUNCTION_DIR}`. There is no runtime file storage.

---

## Aspect 20: Service-to-Service Communication

91. **Services do NOT call each other directly.** There is no inter-service HTTP communication in the Python code. Heroes calls PostgreSQL; names and fortunes are standalone. All service-to-service communication in production flows through API Gateway, not direct service calls.

92. **API Gateway to EKS/Fargate communication uses VPC Links with Network Load Balancers.** The path is: API Gateway -> VPC Link -> NLB -> ECS/K8s service. The `aws_api_gateway_vpc_link` resource targets the NLB ARN. This is the only supported pattern for HTTP_PROXY integration to private VPC resources.

93. **API Gateway to Lambda uses AWS_PROXY integration type.** The `terraform/image-in-lambda/api_gateway.tf` uses `type = "AWS_PROXY"` with `integration_http_method = "POST"` (always POST for Lambda, regardless of the actual HTTP method). See `uri = aws_lambda_function.main.invoke_arn`.

---

## Aspect 21: Security and Compliance Patterns

94. **Security groups use named descriptions for every ingress/egress rule.** The DB security group has `description = "Developer access to PostGRES"` and `description = "VPC access to PostGRES"`. Always include a `description` on security group rules.

95. **Database is placed in VPC database subnets, not private subnets.** The `terraform/all.tf` uses `subnet_group_name = module.vpc.database_subnet_group_name`. The VPC module creates separate database subnet CIDRs (`10.0.7.0/24`, `10.0.8.0/24`).

96. **Developer access to the database is controlled via CIDR blocks, not VPN or bastion host.** The `developer_cidr_blocks` variable (set in `terraform.tfvars` as individual IP `/32` CIDRs) is added as a DB security group ingress rule. The architecture diagram shows a dashed "Bastion?" box indicating it is not implemented.

97. **ECR image scanning is enabled on push.** The `terraform/ecr/main.tf` sets `scan_on_push = true` for all image repositories. This is non-negotiable for all ECR repositories in this project.

98. **IAM roles use least-privilege naming patterns with service-specific names.** Lambda role: `${var.name}-lambda-role`. ECS task role: `ecs-task-role-${var.name}`. ECS exec role: `ecs-exec-role-${var.name}`. The exec role policy is the minimal set needed for ECS: ECR pull, CloudWatch log creation, and Secrets Manager access.

99. **TLS is terminated at API Gateway and CloudFront using ACM certificates.** The API Gateway domain uses `regional_certificate_arn` from an existing ACM cert. CloudFront uses `acm_certificate_arn` with `ssl_support_method = "sni-only"`. Certificates are looked up via `data "aws_acm_certificate"` with the wildcard domain `"*.${var.domain_name}"`.

100. **EKS cluster has all control plane log types enabled.** `cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]` in `terraform/all.tf`. This is the maximum logging configuration for audit compliance.

---

## Key File Locations Reference

- Flask app template: `/Users/jeff/dvp/hoop/services/heroes/src/app.py`
- Lambda handler template: `/Users/jeff/dvp/hoop/services/fortunes/src/app.py`
- Dockerfile (Alpine): `/Users/jeff/dvp/hoop/services/names/Dockerfile`
- Dockerfile (Buster): `/Users/jeff/dvp/hoop/services/heroes/Dockerfile`
- Lambda Dockerfile with RIE: `/Users/jeff/dvp/hoop/services/fortunes/Dockerfile`
- Flask entry.sh: `/Users/jeff/dvp/hoop/services/heroes/entry.sh`
- Lambda entry.sh: `/Users/jeff/dvp/hoop/services/fortunes/entry.sh`
- docker-compose: `/Users/jeff/dvp/hoop/services/docker-compose.yml`
- SQL schema: `/Users/jeff/dvp/hoop/services/postgres/sql/100_CREATE_applicant.sql`
- Postgres Dockerfile: `/Users/jeff/dvp/hoop/services/postgres/Dockerfile`
- Terraform root: `/Users/jeff/dvp/hoop/terraform/all.tf`
- Terraform variables: `/Users/jeff/dvp/hoop/terraform/terraform.tfvars`
- EKS service module: `/Users/jeff/dvp/hoop/terraform/image-in-eks/`
- Fargate service module: `/Users/jeff/dvp/hoop/terraform/image-in-fargate/`
- Lambda service module: `/Users/jeff/dvp/hoop/terraform/image-in-lambda/`
- DB module: `/Users/jeff/dvp/hoop/terraform/db/`
- ECR module: `/Users/jeff/dvp/hoop/terraform/ecr/`
- API Gateway module: `/Users/jeff/dvp/hoop/terraform/rest_api/`
- Deploy workflow template: `/Users/jeff/dvp/hoop/.github/workflows/deploy_heroes.yml`
- Lambda deploy workflow: `/Users/jeff/dvp/hoop/.github/workflows/deploy_fortunes.yml`
