# Juan's Python Golden Path

A deliberately small personal path for going from an idea to a working Python product without repeatedly rebuilding development and deployment infrastructure.

## Mission

> **Build the smallest personal Golden Path that lets me safely and comfortably develop and ship what I know today in roughly 30 minutes, and improve the path only when real projects expose friction.**

The Golden Path exists to remove repeated infrastructure work.

It does not replace the actual work of designing, understanding, coding, debugging, testing, and improving a product.

Speed is currently more valuable than repeatedly reconsidering infrastructure that has already been solved.

---

# 1. Current State

## Golden Path v2 — PROVEN END TO END

The current default project architecture is:

```text
                         Product
                            |
             +--------------+--------------+
             |              |              |
            Web          Worker        PostgreSQL
             |              |              |
             +--------------+--------------+
                            |
                         Coolify
                            |
              https://<project>.jcdelgado.dev
```

The same project also receives a local development stack:

```text
VS Code Dev Container
        |
        +---- Web
        |
        +---- Worker
        |
        +---- PostgreSQL
```

The infrastructure is provisioned before the product logic is written.

The actual application remains a blank canvas.

---

# 2. Golden Path Location

Local source:

```text
C:\Users\jcdel\Root\03_RESOURCES\06_GOLDEN_PATH
```

GitHub backup:

```text
https://github.com/jcbuildstech/golden-path
```

Current structure:

```text
06_GOLDEN_PATH
|-- new_project.bat
|-- README.md
`-- template
    |-- .devcontainer
    |   |-- Dockerfile
    |   |-- compose.yaml
    |   `-- devcontainer.json
    |-- .vscode
    |   `-- settings.json
    |-- .gitattributes
    `-- .gitignore
```

The template deliberately does not contain a starter application.

---

# 3. Normal Project Creation

The outer folder belongs to the PARA organisation system.

Example:

```text
C:\Users\jcdel\Root\01_PROJECTS\15_some_new_idea
```

Copy:

```text
new_project.bat
```

into that outer folder and double-click it.

The batch asks:

```text
Project name:
```

Example:

```text
traffic-monitor
```

The result is:

```text
15_some_new_idea
|-- new_project.bat
`-- traffic-monitor
    |-- .devcontainer
    |-- .vscode
    |-- .gitattributes
    `-- .gitignore
```

The outer folder can use whatever PARA naming convention is useful.

The inner project name is the permanent machine identity.

---

# 4. Project Name Rules

Project names are validated before anything is created.

Allowed:

```text
qld-traffic-monitor
weather-alerts
project2
my-api
```

Rejected:

```text
QLD-Traffic
qld_traffic
qld traffic
-project
project-
```

Rules:

```text
lowercase letters
numbers
hyphens
maximum 63 characters
cannot start with a hyphen
cannot end with a hyphen
```

The same name is used consistently for GitHub, Coolify and the public hostname.

Example:

```text
Project:
traffic-monitor

GitHub:
jcbuildstech/traffic-monitor

Coolify project:
traffic-monitor

Web:
traffic-monitor

Worker:
traffic-monitor-worker

Database:
traffic-monitor-postgres

Production:
https://traffic-monitor.jcdelgado.dev
```

---

# 5. What new_project.bat Creates

Running the batch creates or reuses:

```text
1. Internal project folder
2. Golden Path template
3. Local Git repository
4. Repository-local Git identity
5. Private GitHub repository
6. GitHub origin
7. Coolify project
8. Production PostgreSQL database
9. Coolify Web application
10. Web DATABASE_URL
11. Coolify Worker application
12. Worker DATABASE_URL
13. Permanent public Web hostname
    https://<project>.jcdelgado.dev
```

Resources are looked up before creation.

Rerunning the batch is designed to reuse existing infrastructure instead of duplicating it.

---

# 6. Proven Idempotency

The complete stack was created and then the same batch was run again with the same project name.

Verified result:

```text
Projects:  1
Databases: 1
Web apps:  1
Workers:   1
```

This is important.

Do not remove lookup/reuse logic casually.

---

# 7. Development Environment

The development container uses:

```text
Python 3.12
uv
VS Code Dev Containers
Docker Compose
PostgreSQL 17
```

Dockerfile:

```dockerfile
FROM mcr.microsoft.com/devcontainers/python:3-3.12-trixie

COPY --from=ghcr.io/astral-sh/uv:0.12.13 /uv /uvx /bin/
```

Python 3.12 was deliberately chosen because development and Coolify/Nixpacks production need compatible Python versions.

---

# 8. Local PostgreSQL

PostgreSQL is automatically started beside the Dev Container using Docker Compose.

Architecture:

```text
Dev Container
      |
      | DATABASE_URL
      v
PostgreSQL container
```

Inside the development container the hostname is:

```text
postgres
```

The local connection string is supplied automatically:

```text
postgresql://app:local_dev_only@postgres:5432/app
```

The local database does not need a Windows port, manual startup, or manual `DATABASE_URL` configuration.

The Dev Container waits for PostgreSQL to become healthy.

The PostgreSQL data lives in a Docker volume.

---

# 9. Production PostgreSQL

The batch automatically creates:

```text
PostgreSQL 17
database: app
user: app
```

A strong random database password is generated during project creation.

The password is not committed to Git.

The returned Coolify database UUID is used as the internal database hostname.

Production connection shape:

```text
postgresql://app:<generated-password>@<database-uuid>:5432/app
```

The resulting `DATABASE_URL` is injected into both Web and Worker as a runtime environment variable.

Coolify hides the value in normal output.

---

# 10. Web Application

The Web Coolify application uses:

```text
Repository:
jcbuildstech/<project>

Branch:
main

Build pack:
nixpacks

Port:
8000

Start command:
python main.py
```

A Web application must listen on:

```text
0.0.0.0:8000
```

unless the Golden Path is deliberately changed.

The Web application receives `DATABASE_URL` automatically.

---

# 11. Worker Application

Each project also receives a Worker application.

Configuration:

```text
Repository:
same repository as Web

Branch:
main

Build pack:
nixpacks

Port:
8001

Start command:
python worker.py
```

The Worker receives the same production `DATABASE_URL` as the Web application.

A worker normally does not need HTTP traffic.

Coolify currently generates an `sslip.io` URL for it anyway. That is accepted for this Golden Path because it adds no meaningful friction and the Worker does not need to serve anything.

If a future project becomes important enough to care, the generated Worker domain can be removed manually in Coolify.

Do not complicate the Golden Path solely to remove that harmless URL.

---

# 12. One Repository, Multiple Processes

The default mental model is:

```text
one product
one repository

Coolify project
|-- Web
|-- Worker
`-- PostgreSQL
```

Project, repository and process are not the same thing.

The Web and Worker intentionally use the same Git repository.

They differ by start command:

```text
Web:
python main.py

Worker:
python worker.py
```

Do not split projects into multiple repositories without a real reason.

---

# 13. Public Domain

Cloudflare contains a wildcard DNS record:

```text
*.jcdelgado.dev
```

pointing to:

```text
140.238.198.91
```

with:

```text
DNS only
```

This was configured once.

Because project names are hostname-safe, every future project automatically resolves:

```text
<project>.jcdelgado.dev
```

No per-project Cloudflare DNS work is normally required.

The batch assigns the Web application:

```text
https://<project>.jcdelgado.dev
```

during creation.

---

# 14. HTTPS / TLS

A project receives its permanent HTTPS hostname before application code exists.

The proven sequence is:

```text
new_project.bat
-> custom HTTPS hostname assigned
-> write application
-> first git push
-> Coolify deploys
-> manually redeploy Web once
-> trusted TLS certificate is issued
```

The one manual Web redeploy is currently accepted.

It is tiny friction compared with making the Golden Path more complicated or forcing placeholder application code into every new project.

A successful test with:

```powershell
curl.exe https://<project>.jcdelgado.dev
```

without `-k` proves the certificate is trusted.

---

# 15. Why There Is No Starter Application

The Golden Path deliberately creates infrastructure but not product logic.

It does not automatically create:

```text
main.py
worker.py
database schema
tables
routes
business logic
UI
```

This is intentional.

A starter application could bias the shape of disposable experiments, learning projects and creative projects.

The Golden Path should provide capability, not prescribe the solution.

After opening the project, the first meaningful task should be:

> What does this product actually do?

---

# 16. Normal Development Loop

After project creation, normal work happens inside the Dev Container:

```text
write code
-> test locally
-> git add
-> git commit
-> git push
```

GitHub push automatically triggers both Coolify applications.

Typical commands:

```bash
git status
git add .
git commit -m "Add feature"
git push
```

Routine development should not require manually recreating infrastructure.

---

# 17. First Push

The GitHub repository is intentionally allowed to begin empty.

Coolify can be connected before the repository has its first commit.

The first real:

```bash
git push
```

becomes the first deployment.

This avoids:

```text
placeholder commits
fake starter code
dummy applications
unnecessary first deployments
```

The project begins with the actual thing being built.

---

# 18. Proven Full Architecture

The Golden Path was tested with a real end-to-end heartbeat application.

Local test:

```text
Worker
  |
  | writes heartbeat
  v
PostgreSQL
  ^
  | reads heartbeat
  |
Web
  |
  v
Browser
```

Production test:

```text
Coolify Worker
      |
      | DATABASE_URL
      v
Coolify PostgreSQL
      ^
      | DATABASE_URL
      |
Coolify Web
      |
      v
HTTPS
```

The production Web successfully returned Worker heartbeat data written through the shared PostgreSQL database.

This proves:

```text
Worker deployment
PostgreSQL connectivity
Web deployment
shared DATABASE_URL
database writes
database reads
public routing
custom domain
trusted TLS
```

---

# 19. Secrets

Never hardcode or commit:

```text
GitHub tokens
Coolify API tokens
production database passwords
API keys
private keys
other credentials
```

Authentication belongs outside source code.

Current locations:

```text
GitHub authentication:
Windows GitHub CLI / credential storage

Coolify authentication:
Coolify CLI context

Production DATABASE_URL:
Coolify environment variables

Local DATABASE_URL:
disposable local development configuration
```

The generated production database password exists temporarily while the batch provisions the project and is then cleared from the batch environment.

---

# 20. GitHub

GitHub owner:

```text
jcbuildstech
```

Professional Git identity:

```text
Juan Delgado Vivas
jcbuildstech@gmail.com
```

New repositories are `PRIVATE` by default.

A repository becomes public only when there is a reason.

Before making a portfolio repository public, perform a secret/history scan.

---

# 21. Git Inside Dev Containers

Normal Git workflow happens inside the Dev Container.

VS Code forwards Git credentials from Windows.

Therefore:

```bash
git push
```

works even if:

```bash
gh auth status
```

inside the Dev Container says GitHub CLI is not logged in.

Do not authenticate GitHub CLI inside every Dev Container unless a project specifically requires `gh`.

---

# 22. Virtual Environment

The Python environment lives in:

```text
/home/vscode/.venv
```

configured through:

```text
UV_PROJECT_ENVIRONMENT=/home/vscode/.venv
```

It intentionally does not live inside the Windows-mounted project directory.

If the environment is lost:

```bash
uv sync
```

recreates it from:

```text
pyproject.toml
uv.lock
```

---

# 23. Dependency Management

Use:

```bash
uv add requests
uv add flask
uv add "psycopg[binary]"
```

instead of manually managing packages with `pip`.

`uv` maintains:

```text
pyproject.toml
uv.lock
```

The Dev Container runs `uv sync` during setup.

---

# 24. Git Safety

The Dev Container configures the current repository as a Git safe directory:

```bash
git config --global --add safe.directory "$(pwd)"
```

This solves ownership differences caused by Windows-mounted repositories.

Do not replace this with:

```text
safe.directory *
```

because that disables the safety mechanism globally.

---

# 25. Production Build

Development:

```text
.devcontainer/Dockerfile
```

Production:

```text
Coolify + Nixpacks
```

These are separate concerns.

Do not assume the development Dockerfile must also become the production image.

The current Nixpacks path is proven on the OCI ARM64 server.

---

# 26. Coolify Infrastructure

Server UUID:

```text
ew0ckwcs444o4c0s4s0000so
```

GitHub App UUID:

```text
ugwgsgowsgskc4w40ws4s0sc
```

These UUIDs are identifiers, not credentials.

The Coolify API token is stored in the CLI context and must never be placed in the batch file.

GitHub App repository access is configured so newly created repositories can be deployed without manually granting access each time.

---

# 27. Important Coolify / CLI Quirks

Some Coolify CLI commands return incomplete-looking table output even when the operation succeeds.

For example, creation or update commands can show a UUID while other fields appear blank.

Verify using:

```powershell
coolify app get <uuid>
```

or:

```powershell
coolify app list --format json
```

Do not interpret blank table fields as automatic failure.

Another proven implementation detail:

Directly capturing some Coolify JSON values through Batch `FOR /F` produced unreliable whitespace results.

The current proven pattern is:

```text
Coolify CLI
-> JSON temporary file
-> PowerShell parses JSON
-> PowerShell writes UUID or state to result file
-> Batch reads result with set /p
```

Do not simplify this unless the replacement is tested with a completely fresh project.

---

# 28. Batch Delayed Expansion

The batch uses:

```text
EnableDelayedExpansion
```

because variables generated inside parenthesised Batch blocks must be read after they are assigned.

This matters particularly for:

```text
generated database password
DATABASE_URL
```

Inside those blocks use:

```text
!VARIABLE!
```

rather than:

```text
%VARIABLE%
```

where delayed values are required.

This bug was discovered through a real disposable-project test.

---

# 29. Failure Philosophy

Do not diagnose from assumptions.

Test the failing boundary.

Examples:

```text
Can Dev Container reach local PostgreSQL?

Can the application create a table?

Can the Worker write?

Can Web read the same row?

Did Coolify receive DATABASE_URL?

Did the first push deploy?

Does the custom hostname resolve?

Is TLS trusted?
```

A failed test should expose the next piece of friction.

Fix the Golden Path source only after the problem is understood.

---

# 30. Golden Path Development Rule

Before changing the Golden Path:

```text
1. Reproduce the problem.
2. Change the Golden Path source.
3. Test with a completely fresh disposable project.
4. Test locally.
5. Test production.
6. Test first push.
7. Test the relevant Web / Worker / database path.
8. Rerun new_project.bat.
9. Verify no duplicate infrastructure was created.
10. Commit.
11. Push the Golden Path.
```

This process produced the current system.

---

# 31. What Not to Automate

Do not turn the Golden Path into:

```text
a framework
a platform
Kubernetes
a universal deployment engine
a giant abstraction layer
a DevOps hobby project
```

Do not automate:

```text
business logic
database schema
UI decisions
data modelling
application architecture beyond the default runtime plumbing
```

Those are part of doing the actual work.

---

# 32. Default vs Requirement

The Golden Path provisions:

```text
Web
Worker
PostgreSQL
GitHub
Coolify
custom domain
```

by default.

That does not mean every project intrinsically needs all of them.

For the current stage of development, having the capability available is cheaper than repeatedly stopping to decide whether it might eventually be needed.

Unused infrastructure can simply remain unused.

The expensive resource is developer attention.

---

# 33. Jobs / Scheduled Processes

Scheduled Job support is not currently automated.

If a real project needs:

```text
cron
scheduled imports
daily reports
periodic cleanup
one-shot tasks
```

solve that requirement from the real project and then decide whether it belongs in the Golden Path.

Do not implement Job support merely because it might someday be useful.

---

# 34. Recovery on a New Machine

Basic recovery:

```text
Install Git
Install Docker Desktop
Install VS Code
Install GitHub CLI
Authenticate GitHub CLI
Install Coolify CLI
Configure Coolify context
Clone golden-path
Restore it to:
C:\Users\jcdel\Root\03_RESOURCES\06_GOLDEN_PATH
```

Cloudflare wildcard DNS is account-side infrastructure and does not need to be recreated for every development machine.

---

# 35. Current Workflow

The current practical workflow is:

```text
IDEA

-> create outer PARA folder
-> copy new_project.bat
-> double-click
-> enter project name
-> infrastructure is provisioned
-> open generated project folder in VS Code
-> Reopen in Container
-> start solving the actual problem
-> test locally
-> git commit
-> git push
-> Web + Worker deploy
-> manually redeploy Web once when trusted TLS is needed
-> https://<project>.jcdelgado.dev
-> continue building
```

---

# 36. Success Criterion

The Golden Path succeeds when the thought:

> I want to build this.

can quickly become:

```text
folder
-> batch
-> infrastructure
-> Dev Container
-> code
-> test
-> push
-> live
```

without needing to remember the deployment plumbing.

---

# 37. Current Milestone

## COMPLETE PRODUCT INFRASTRUCTURE PATH — PROVEN

Proven:

```text
validated project naming
PARA outer folder separation
Dev Container
Python 3.12
uv
local PostgreSQL
private GitHub repository
Coolify project
production PostgreSQL
Web application
Worker application
shared DATABASE_URL
automatic deployment on push
wildcard DNS
automatic permanent Web hostname
trusted HTTPS after one Web redeploy
full Worker -> PostgreSQL -> Web production data path
idempotent reruns
```

The Golden Path should now remain stable until a real project exposes new friction.

---

# 38. Message to Future Juan / Future Assistant

The current system was built by following one rule:

> **Improve the path only when real projects expose friction.**

Do not redesign it because a theoretically cleaner architecture exists.

Do not add complexity merely because automation is possible.

Do not confuse infrastructure automation with doing the actual work.

The Golden Path should make starting cheap.

The project itself is where the hard work belongs.
