# Container workflow

The Flask banking application is packaged as a multi-stage, non-root image for local testing and the later Kubernetes deployment phase.

## Runtime design

- Python `3.14-slim` is pinned to a verified multi-architecture registry digest for build and runtime stages.
- The builder installs the packaged application into an isolated prefix.
- The runtime image receives only the installed package and Gunicorn configuration.
- Package installers and build tooling are removed from the runtime image.
- Gunicorn runs as UID/GID `10001`, never as root.
- The service listens on container port `8080`.
- The built-in health check calls `/healthz` without installing curl in the image.
- Build context rules exclude Git history, virtual environments, tests, credentials, Terraform data, and unrelated project directories.

## Start the runtime

Start Colima with the reviewed project allocation:

```bash
colima start --cpu 4 --memory 8 --disk 60
```

This starts the local container virtual machine only. It does not create a kind cluster.

## Build and validate

```bash
make container-build
make container-scan
make container-run
make container-smoke
```

Open the dashboard at `http://127.0.0.1:8080`.

Inspect the running process and health status:

```bash
docker inspect --format '{{.State.Health.Status}}' muma-bank-local
docker exec muma-bank-local id
docker logs muma-bank-local
```

Expected identity:

```text
uid=10001(app) gid=10001(app) groups=10001(app)
```

## Clean shutdown

Stop the application gracefully and remove only its stopped container:

```bash
make container-stop
make container-remove
```

Stop Colima while preserving its virtual machine and image data:

```bash
colima stop
```

Verify no project runtime remains:

```bash
docker context show
colima status
lsof -nP -iTCP:8080 -sTCP:LISTEN
```

Do not use `docker system prune`, `kind delete cluster`, or force-removal commands for this workflow.
