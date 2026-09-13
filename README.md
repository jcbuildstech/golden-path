# Juan's Python Golden Path

A deliberately small personal development and deployment path for Python projects.

## Mission

> **Build the smallest personal golden path that lets me safely AND COMFORTABLY develop and ship what I know today in roughly 30 minutes, and improve the path only when real projects expose friction.**

This is not meant to become a framework, platform, or DevOps hobby project. Its purpose is to reduce repeated setup and deployment friction so the focus stays on building actual projects.

---

# 1. Current Status

## Web Golden Path — PROVEN END TO END

As of September 2026, the Web path has been tested from a completely empty project through to a live deployment.

The proven flow is:

```text
Create project folder
    ↓
Copy new_project.bat into the folder
    ↓
Run new_project.bat
    ↓
Golden Path template copied
    ↓
Local Git repository created
    ↓
Private GitHub repository created
    ↓
Coolify project created
    ↓
Coolify application created and connected
    ↓
Open project in VS Code
    ↓
Reopen in Dev Container
    ↓
Write code
    ↓
git commit
    ↓
git push
    ↓
Coolify automatically detects push
    ↓
Builds on OCI ARM64
    ↓
Application becomes live
```

The normal development loop is now:

```text
VS Code Dev Container
→ code
→ test
→ git add / commit
→ git push
→ Coolify automatically redeploys
```

No manual Coolify setup is required after project creation.

---

# 2. Golden Path Location

Local source:

```text
C:\Users\jcdel\Root\03_RESOURCES\06_GOLDEN_PATH
```

Private GitHub backup:

```text
https://github.com/jcbuildstech/golden-path
```

Current structure:

```text
06_GOLDEN_PATH
├── new_project.bat
├── README.md
└── template
    ├── .devcontainer
    │   ├── Dockerfile
    │   └── devcontainer.json
    ├── .vscode
    │   └── settings.json
    ├── .gitattributes
    └── .gitignore
```

Fresh projects later generate additional files such as:

```text
pyproject.toml
uv.lock
.devcontainer/devcontainer-lock.json
```

---

# 3. Current Scope

The current `new_project.bat` is a **Web-project Golden Path**.

Current assumptions:

```text
Language:       Python
Python:         3.12
Dependency mgr: uv
Build system:   Nixpacks
Entry point:    python main.py
Web port:       8000
Git branch:     main
GitHub:         private repository
Deployment:     Coolify
Server:         OCI ARM64
```

A Web project must eventually listen on:

```text
0.0.0.0:8000
```

unless the Golden Path is intentionally changed.

The current batch does **not** yet support Worker or Job project types.

---

# 4. Program-Type Mental Model

The important distinction is not “what framework is this?” but:

1. What starts the program?
2. Does it stay alive or exit?
3. What is it waiting for?

Common runtime shapes:

## Web

```text
starts
→ stays alive
→ waits for HTTP requests
```

Examples:

- Flask
- FastAPI
- Django
- REST API
- backend service

## Worker

```text
starts
→ stays alive
→ performs background work
```

Example:

```python
while True:
    check_traffic()
    send_notifications()
    sleep(...)
```

The QLD traffic notification system is naturally shaped like a Worker.

A Worker normally needs:

```text
no public port
no public URL
no Traefik route
```

It may still make outgoing API calls.

## Job

```text
starts
→ performs work
→ exits
```

Examples:

- daily report
- cleanup script
- periodic importer
- scheduled data task

Job support has not yet been implemented because no real project has required it.

---

# 5. One Product Can Contain Multiple Processes

Do not confuse:

```text
project
process
repository
```

They are not the same thing.

A future product might look like:

```text
Fantasy League
├── business logic
├── API / web process
├── worker process
├── scheduled job
└── frontend
```

These can initially live in one repository.

Do not split into separate repositories unless a real reason appears, such as:

- independent release cycles
- independent teams
- radically different scaling
- one component becoming independently reusable

For a solo developer, splitting too early creates unnecessary Git, deployment, config, auth, and mental overhead.

---

# 6. Development Environment

## Python

The Golden Path now standardises on:

```text
Python 3.12
```

Current Dockerfile:

```dockerfile
FROM mcr.microsoft.com/devcontainers/python:3-3.12-trixie

COPY --from=ghcr.io/astral-sh/uv:0.12.13 /uv /uvx /bin/
```

The Dev Container was tested with:

```text
Python 3.12.14
```

---

# 7. Why Python 3.12 Was Chosen

The Golden Path originally used Python 3.14.

That caused `uv init` to create:

```toml
requires-python = ">=3.14"
```

Coolify/Nixpacks on OCI provided Python 3.12.

Deployment then failed with:

```text
error: No interpreter found for Python >=3.14
```

The fix was made at the Golden Path source instead of patching individual projects.

Fresh projects now generate:

```toml
requires-python = ">=3.12"
```

Important lesson:

> Development and production Python versions should be deliberately aligned.

---

# 8. Dependency Management

The Golden Path uses:

```text
uv
```

The intended dependency workflow is:

```bash
uv add requests
```

rather than:

```bash
pip install requests
```

`uv` maintains:

```text
pyproject.toml
uv.lock
```

The Dev Container restores dependencies automatically with `uv sync`.

---

# 9. Virtual Environment Design

The virtual environment deliberately lives inside the Linux container filesystem:

```text
/home/vscode/.venv
```

Not inside the Windows-mounted project directory.

Configured with:

```text
UV_PROJECT_ENVIRONMENT=/home/vscode/.venv
```

VS Code interpreter:

```text
/home/vscode/.venv/bin/python
```

Reason:

The project folder lives on Windows NTFS and is mounted into Linux.

Keeping `.venv` inside the mounted project previously caused deletion and filesystem friction.

The Linux-side environment is disposable.

If lost:

```bash
uv sync
```

rebuilds it from:

```text
pyproject.toml
uv.lock
```

---

# 10. Persistent-State Lesson

A previous project exposed an important filesystem rule.

SQLite WAL mode behaved badly on the Windows-mounted NTFS project filesystem.

The traffic project therefore moved its working database to native Linux storage:

```text
/home/vscode/.local/share/accident_notification/traffic.db
```

Lesson:

> Source code can live in the Windows-mounted project directory. Runtime state that depends on Linux filesystem semantics should live on native Linux storage or a proper volume.

The Golden Path does not currently impose a database architecture.

Add one only when a real project needs it.

---

# 11. Git Configuration

Each project receives repository-local Git identity:

```text
user.name  = Juan Delgado Vivas
user.email = jcbuildstech@gmail.com
```

Also configured:

```text
push.autoSetupRemote = true
```

This lets the first:

```bash
git push
```

set upstream automatically.

---

# 12. Git Safe Directory Fix

Windows-mounted repositories inside Dev Containers can appear to Git as having suspicious ownership.

This previously caused:

```text
fatal: detected dubious ownership in repository
```

The Dev Container setup fixes the current project dynamically:

```bash
git config --global --add safe.directory "$(pwd)"
```

Do not replace this with:

```text
safe.directory *
```

because that would disable the safety mechanism globally.

---

# 13. GitHub

GitHub account:

```text
jcbuildstech
```

Professional email:

```text
jcbuildstech@gmail.com
```

Projects are created as:

```text
PRIVATE GitHub repositories
```

by default.

A project can later be made public manually if it becomes portfolio-worthy.

The Golden Path never stores GitHub tokens in source.

Authentication lives in Windows credential storage through GitHub CLI.

---

# 14. GitHub Credentials in Dev Containers

`gh auth status` inside a Dev Container may say GitHub CLI is not logged in.

That is okay.

VS Code Dev Containers forward Git credentials from the Windows host.

This was explicitly tested:

```bash
git push
```

worked from inside the container without:

- browser login
- token entry
- PowerShell
- `gh auth login` inside the container

Normal workflow therefore remains:

```text
Dev Container
→ git commit
→ git push
```

---

# 15. Coolify

Coolify runs on Juan's OCI server.

Current deployment server UUID:

```text
ew0ckwcs444o4c0s4s0000so
```

Coolify identifies the server as:

```text
localhost
```

The UUID is an identifier, not a secret.

---

# 16. Coolify CLI

Official Coolify CLI is installed on Windows.

Version used during Golden Path development:

```text
1.8.0
```

Configured context:

```text
production
```

Connectivity can be checked with:

```powershell
coolify context verify
```

The Coolify API token is stored in the CLI context.

Never put the token inside `new_project.bat`.

---

# 17. Coolify GitHub App

Current GitHub App UUID used by the Golden Path:

```text
ugwgsgowsgskc4w40ws4s0sc
```

GitHub App name:

```text
weary-wolf-ocs40484c44s848wwc0
```

Repository access was changed to:

```text
All repositories
```

This matters because if access were restricted to selected repositories, every new Golden Path project would require manual GitHub permission changes and the automation would stop being useful.

---

# 18. Coolify GitHub CLI/API Quirk

A CLI/API mismatch was discovered.

This command:

```powershell
coolify github repos ugwgsgowsgskc4w40ws4s0sc
```

failed because the server attempted to interpret the GitHub App UUID as a PostgreSQL bigint.

`coolify github list --format json` showed:

```text
weary-wolf internal id: 1
UUID: ugwgsgowsgskc4w40ws4s0sc
```

This command worked:

```powershell
coolify github repos 1
```

Important:

The application creation command itself **does** correctly accept the GitHub App UUID:

```text
ugwgsgowsgskc4w40ws4s0sc
```

Do not replace it with numeric `1` in `new_project.bat` unless the API changes and is re-tested.

---

# 19. Coolify Project Strategy

Golden Path decision:

> **One shipped idea = one Coolify project.**

Do not put every unrelated Golden Path app inside one giant Coolify project.

The desired mental organisation is:

```text
fantasy_league
traffic_notifier
expense_analyser
next_idea
```

A single Coolify project may later contain more than one runtime resource if the product needs it.

Example:

```text
Fantasy League Coolify Project
├── API
├── Worker
└── Database
```

---

# 20. Web Deployment Configuration

The current Web Golden Path creates a Coolify application using:

```text
Git repository:
jcbuildstech/<project_name>

Branch:
main

Build pack:
nixpacks

Port:
8000

Start command:
python main.py

Environment:
production
```

The batch deliberately does **not** use:

```text
--instant-deploy
```

during creation.

---

# 21. Why the Batch Does Not Deploy Immediately

A key behaviour was explicitly tested.

Coolify can be connected to a completely empty GitHub repository before that repository has any commits.

Then the first:

```bash
git push
```

automatically triggers the first deployment.

This was proven using:

```text
12_first_push_test
```

Sequence:

```text
empty GitHub repo
→ Coolify project created
→ Coolify app created
→ no deployment
→ first commit
→ first git push
→ Coolify webhook triggered
→ deployment finished
→ live application worked
```

Therefore the Golden Path does not need:

- placeholder commits
- dummy deployments
- manual first deploy
- fake starter code

---

# 22. Auto Deploy

Coolify auto-deploy from GitHub is proven.

Test:

```text
edit main.py
→ git commit
→ git push
```

Coolify automatically created and completed a deployment for the new commit.

The live app then served the updated output.

The intended normal deployment workflow is therefore simply:

```bash
git push
```

---

# 23. ARM64

The OCI server is ARM64.

During deployment, Nixpacks successfully downloaded and installed ARM64/aarch64 Python tooling.

The deployment logs showed an ARM64 uv wheel being installed successfully.

Therefore the current Python + Nixpacks path already works on the OCI architecture.

Do not add custom ARM64 build logic unless a real dependency proves it is necessary.

---

# 24. Domains

Coolify currently provides temporary public URLs using:

```text
sslip.io
```

Typical form:

```text
http://<app-uuid>.<server-ip>.sslip.io
```

This is enough for:

> idea → live

Custom Cloudflare domains are deliberately not automated yet.

Manual Cloudflare + DNS + Traefik setup was previously a major source of deployment friction.

Do not reintroduce that complexity until a real project needs a permanent domain.

---

# 25. HTTP / HTTPS

HTTP/HTTPS was initially suspected during one failed deployment.

That was not the actual problem.

The failure happened earlier during the build because of the Python 3.14 vs 3.12 mismatch.

Lesson:

> Read build/deployment logs before assuming routing, DNS, Traefik, or HTTPS is the cause.

---

# 26. Nixpacks vs Dev Container

The Dev Container Dockerfile is for development:

```text
.devcontainer/Dockerfile
```

Production deployment currently uses:

```text
Coolify + Nixpacks
```

These are separate concerns.

Mental model:

```text
.devcontainer/Dockerfile
→ local development environment

Coolify + Nixpacks
→ production build/runtime
```

Do not assume the development Dockerfile must also be the production image.

---

# 27. What `new_project.bat` Does

Current responsibilities:

```text
1. Determine project name from containing folder

2. Copy Golden Path template

3. Initialise local Git repo if missing

4. Configure repository-local Git identity

5. Configure push.autoSetupRemote

6. Create private GitHub repo if missing

7. Add GitHub origin if missing

8. Search Coolify for a project with the same project name

9. Reuse Coolify project if found

10. Create Coolify project if missing

11. Search Coolify apps for:
    jcbuildstech/<project_name>

12. Reuse Coolify app if found

13. Create Coolify Web app if missing

14. Leave deployment idle until first git push

15. Exit clearly if setup fails
```

---

# 28. Idempotency

Running `new_project.bat` twice on the same project was explicitly tested.

Test project:

```text
15_batch_web_test
```

After running the batch twice:

```text
Projects: 1
Apps: 1
```

Therefore the current Web bootstrap reuses existing Coolify resources rather than silently duplicating them.

Do not remove the lookup/reuse logic casually.

---

# 29. Important Batch Implementation Detail

An early implementation attempted to capture PowerShell output directly through:

```bat
for /f ...
```

When no Coolify resource existed, the command unexpectedly produced/captured a single space:

```text
UUID=[ ]
RESULT=DEFINED
```

This caused the batch to think a Coolify project already existed and skip creation.

That direct capture method was abandoned.

The proven method is now:

```text
Coolify CLI
→ JSON temp file
→ PowerShell reads JSON
→ PowerShell writes UUID/NONE to temp result file
→ batch reads result with set /p
```

It is less elegant, but it was tested and works.

Do not “simplify” back to the broken direct capture approach without re-testing it.

---

# 30. Coolify JSON Response Quirks

Creating a project with:

```powershell
coolify project create --name "example" --format json
```

may return:

```json
{
  "uuid": "...",
  "name": ""
}
```

The blank name does not mean creation failed.

The UUID is valid.

Confirm using:

```powershell
coolify project list --format json
```

Similarly, immediately after application creation, some CLI table fields may be blank.

Verify later using:

```powershell
coolify app get <uuid>
```

or:

```powershell
coolify app list --format json
```

---

# 31. Proven Test Projects

## 10_github_test

Used to prove:

- private GitHub repo creation
- Git credential forwarding into Dev Containers
- Coolify private GitHub app creation
- initial Nixpacks deployment
- root cause of Python version mismatch

## 11_python312_test

Used to prove:

- Golden Path source changed to Python 3.12
- fresh Dev Container generated `requires-python >=3.12`
- Nixpacks deployment works on OCI ARM64
- subsequent `git push` automatically redeploys

## 12_first_push_test

Used to prove:

> Coolify can be wired to an empty GitHub repo and automatically deploy the first-ever push.

## 13_json_probe

Used to inspect Coolify project-create JSON.

## 14_batch_web_test

Used while diagnosing the broken direct `FOR /F` capture approach.

## 15_batch_web_test

Final Web-path proof.

The batch itself successfully:

```text
created private GitHub repo
created Coolify project
created Coolify application
```

Then:

```text
first git push
→ automatic deployment
→ live response
```

Live response:

```text
Golden Path batch deployment works!
```

Then the batch was run again and verified:

```text
Projects: 1
Apps: 1
```

---

# 32. Normal Project Workflow

Once a project exists, normal development should happen almost entirely inside VS Code / Dev Container.

Example:

```bash
git status
git add .
git commit -m "Add feature"
git push
```

That should be enough for deployment.

Do not manually create GitHub/Coolify resources or trigger routine deployments unless something has actually broken.

---

# 33. Project Creation Workflow

Expected workflow:

```text
1. Create a folder manually

C:\Users\jcdel\Root\01_PROJECTS\16_new_idea

2. Copy new_project.bat into it

3. Run new_project.bat

4. Start Docker Desktop

5. Open project folder in VS Code

6. Reopen in Dev Container

7. Write application

8. Test locally

9. Commit

10. git push

11. Coolify deploys automatically
```

---

# 34. Git Line Endings

Host:

```text
Windows
```

Development/runtime:

```text
Linux
```

Template includes:

```text
.gitattributes
```

with:

```text
* text=auto eol=lf
```

Template files were normalised to LF.

The `.bat` itself may use Windows CRLF.

That is fine.

---

# 35. Secrets

Never hardcode or commit:

```text
GitHub tokens
Coolify API token
API keys
passwords
database passwords
private keys
```

Authentication lives in:

```text
Windows credential storage
GitHub CLI auth
Coolify CLI context
```

---

# 36. Recovery on a New Machine

Typical recovery:

```text
Install Git
Install Docker Desktop
Install VS Code
Install GitHub CLI
Authenticate gh
Install Coolify CLI
Configure Coolify context
Clone golden-path
Restore to:
C:\Users\jcdel\Root\03_RESOURCES\06_GOLDEN_PATH
```

This does not need extreme automation because it should happen rarely.

---

# 37. Coolify Upgrade / Backup Lesson

Coolify was originally found on:

```text
v4.0.0-beta.452
```

Before upgrading, an OCI boot-volume backup was created.

Coolify was upgraded successfully.

The GitHub repository-list UUID bug remained, showing it was not simply caused by the older version.

Lesson:

> Before future major Coolify upgrades, create an OCI boot-volume backup.

---

# 38. Future Runtime-Type Plan

Long-term:

```text
new_project.bat

What are you building?

[1] Web
[2] Worker
```

Possibly later:

```text
[3] Job
```

But options should only be added when real projects prove they are needed.

Current state:

```text
Web → complete and proven
Worker → not yet implemented
Job → not yet implemented
```

---

# 39. Next Major Milestone

## Worker Path

Use the real:

```text
QLD Traffic Accident / Traffic Event Notification System
```

Its runtime shape is:

```text
start
→ fetch QLD traffic data
→ normalise
→ compare state
→ send ntfy notifications
→ wait
→ repeat
```

Questions should be answered from the real project, not pure theory:

```text
How should Coolify represent the worker?

What start command should it use?

Does it require an exposed port?

What restart behaviour is appropriate?

How should graceful shutdown work?

Should polling remain an infinite loop or move to an external scheduler?

How should environment variables be supplied?

How should persistent state be mounted?
```

---

# 40. Possible Future Improvements

Only add when real friction appears:

```text
Worker project type
Scheduled-job project type
custom Cloudflare domain automation
environment-variable helper
persistent storage helper
database creation
project-specific port
project-specific start command
health checks
deployment status feedback
one-command make-public
project cleanup tooling
```

---

# 41. Things Not to Do

Do not turn this into:

```text
a platform
a framework
Kubernetes
a universal deployment engine
a giant abstraction layer
a DevOps hobby project
```

The Golden Path exists to help Juan build projects.

If maintaining it starts consuming more time than building applications, the design has drifted.

---

# 42. Success Criterion

The Golden Path is successful when Juan can think:

> “I want to build this.”

and quickly move to:

```text
folder
→ batch
→ Dev Container
→ code
→ push
→ live
```

without needing to remember deployment plumbing.

---

# 43. Current Milestone

## WEB PATH — COMPLETE AND PROVEN

Current milestone files:

```text
new_project.bat
template/.devcontainer/Dockerfile
README.md
```

Next milestone:

```text
WORKER PATH
```

---

# 44. Message to Future Juan / Future Assistant

Before changing the Golden Path:

1. Read this README.
2. Check Git history.
3. Reproduce the problem before changing anything.
4. Change the Golden Path source, not only the affected project.
5. Test with a completely fresh disposable project.
6. Test first push.
7. Test subsequent push.
8. Test rerunning the batch.
9. Verify no duplicate GitHub/Coolify resources were created.
10. Only then commit the Golden Path change.

Most importantly:

> **Do not optimise this system for imagined future complexity.**

The rule remains:

> **Improve the path only when real projects expose friction.**
