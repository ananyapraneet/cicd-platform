# CI/CD Platform

A DevOps-focused project demonstrating a complete CI/CD platform for deploying a containerized application to Kubernetes.

The application itself is intentionally simple. The primary objective of this project is to demonstrate the engineering practices surrounding **CI/CD, containerization, security, artifact management, Kubernetes, Helm, environment
separation, and automated delivery**.

---

## Architecture

```text
Developer
    ↓
GitHub
    ↓
Pull Request
    ↓
GitHub Actions
    ↓
Tests
    ↓
Docker Build
    ↓
Security Scan
    ↓
GitHub Container Registry
    ↓
Kubernetes
    ↓
Helm
    ↓
Environment
    ↓
Application
```

The platform is designed around an immutable artifact workflow:

```text
Source Code
    ↓
CI
    ↓
Docker Image
    ↓
Security Scan
    ↓
GHCR
    ↓
Kubernetes / Helm
```

Docker images are identified using the Git commit SHA rather than mutable tags such as `latest`.

---

## Technologies

* Python
* FastAPI
* Git
* GitHub
* GitHub Actions
* Docker
* Trivy
* GitHub Container Registry (GHCR)
* Kubernetes
* kind
* Helm

---

## Application

The application is intentionally minimal because the focus of this project is the delivery platform surrounding it.

### Endpoints

#### `GET /`

Returns a simple application message.

Example:

```json
{
  "message": "CI/CD Platform API"
}
```

#### `GET /health`

Returns the application health status.

Example:

```json
{
  "status": "healthy"
}
```

The `/health` endpoint is also used by Docker and Kubernetes health checks.

---

## Project Structure

```text
cicd-platform/
├── app/
│   ├── __init__.py
│   └── main.py
│
├── tests/
│   └── test_main.py
│
├── helm/
│   └── cicd-platform/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-prod.yaml
│       ├── .helmignore
│       └── templates/
│           ├── _helpers.tpl
│           ├── deployment.yaml
│           └── service.yaml
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── Dockerfile
├── .dockerignore
├── .gitignore
├── requirements.txt
└── README.md
```

---

# CI/CD Pipeline

The GitHub Actions pipeline currently performs the following steps:

```text
Checkout
   ↓
Set up Python 3.12
   ↓
Install dependencies
   ↓
Run tests
   ↓
Build Docker image
   ↓
Trivy security scan
   ↓
Authenticate with GHCR
   ↓
Tag image with Git SHA
   ↓
Push image to GHCR
```

The pipeline runs for:

* Pull requests targeting `main`
* Pushes to `main`

### Testing

The application currently contains automated tests for:

* Root endpoint
* Health endpoint

Tests are executed using:

```bash
python -m pytest -v
```

---

# Containerization

The application is containerized using Docker.

The Docker image:

* Uses `python:3.12-slim`
* Runs as a non-root user
* Exposes port `8000`
* Includes a Docker health check
* Uses `PYTHONDONTWRITEBYTECODE`
* Uses `PYTHONUNBUFFERED`
* Installs dependencies without retaining pip cache

The application container runs as:

```text
appuser
```

rather than `root`.

---

# Security Scanning

Docker images are scanned using **Trivy** before being published to the container registry.

The CI pipeline checks for:

* CRITICAL vulnerabilities
* HIGH vulnerabilities
* Secrets

Unfixed vulnerabilities are ignored to prevent known-but-unfixable base-image issues from blocking the pipeline.

The image must pass the security scanning stage before it is pushed to GHCR.

---

# Container Registry

Docker images are published to **GitHub Container Registry (GHCR)**.

Image format:

```text
ghcr.io/ananyapraneet/cicd-platform:<git-sha>
```

Example:

```text
ghcr.io/ananyapraneet/cicd-platform:bc39a26c72ff65df28808955ca5c9b4d6c5a7f9a
```

Using the Git commit SHA provides immutable image identification and allows Kubernetes deployments to reference an exact application artifact.

The pipeline does not depend on the mutable `latest` tag.

---

# Kubernetes

The application is deployed to Kubernetes using a local `kind` cluster for development and platform testing.

Cluster:

```text
kind-cicd-platform
```

The application runs as a Kubernetes Deployment with:

* Multiple replicas
* Readiness probes
* Liveness probes
* ClusterIP service
* Kubernetes-managed rolling deployments

The `/health` endpoint is used for both readiness and liveness checks.

---

# Helm

Kubernetes deployment configuration is managed using Helm.

Chart:

```text
helm/cicd-platform
```

The Helm chart manages:

* Deployment
* Service
* Replica configuration
* Container image
* Image pull policy
* Liveness probe
* Readiness probe
* Resource configuration

Example installation:

```bash
helm install cicd-platform helm/cicd-platform
```

The chart uses Helm release names to allow multiple environments to coexist in the same Kubernetes cluster.

---

# Environment Separation

Environment-specific configuration is managed through separate Helm values files.

```text
helm/cicd-platform/
├── values.yaml
├── values-dev.yaml
└── values-prod.yaml
```

The same Helm templates are reused across environments.

```text
                    Helm Chart
                        │
             ┌──────────┴──────────┐
             ↓                     ↓
       values-dev.yaml       values-prod.yaml
             ↓                     ↓
      Development             Production
```

## Development

Development uses:

```yaml
replicaCount: 1
```

Deployment:

```text
cicd-platform-dev
```

## Production

Production uses:

```yaml
replicaCount: 3
```

Deployment:

```text
cicd-platform-prod
```

Both environments currently deploy the same immutable Docker image identified by its Git commit SHA.

This demonstrates separation of environment configuration without duplicating Kubernetes templates.

### Render Development

```bash
helm template cicd-platform-dev helm/cicd-platform \
  -f helm/cicd-platform/values-dev.yaml
```

### Render Production

```bash
helm template cicd-platform-prod helm/cicd-platform \
  -f helm/cicd-platform/values-prod.yaml
```

---

# Deployment Verification

Development:

```bash
helm upgrade --install cicd-platform-dev helm/cicd-platform \
  -f helm/cicd-platform/values-dev.yaml
```

Production:

```bash
helm upgrade --install cicd-platform-prod helm/cicd-platform \
  -f helm/cicd-platform/values-prod.yaml
```

Current environment configuration:

```text
Development → 1 replica
Production  → 3 replicas
```

Both environments successfully pass Kubernetes rollout verification.

---

# Git Workflow

The project follows a feature-branch and pull-request workflow.

```text
main
 ├── feature/helm
 ├── feature/environment-separation
 ├── feature/automated-deployment
 ├── feature/rollback
 └── feature/observability
```

Development workflow:

```text
Create feature branch
        ↓
Implement feature
        ↓
Test locally
        ↓
Push feature branch
        ↓
Create Pull Request
        ↓
GitHub Actions CI
        ↓
Review
        ↓
Merge into main
        ↓
Create next feature branch
```

This keeps the `main` branch stable and makes each major DevOps capability independently reviewable.

---

# Project Progress

## Stage 1 — Application + Repository

* [x] Simple FastAPI application
* [x] Git repository
* [x] GitHub repository
* [x] Initial README
* [x] Application endpoints
* [x] Automated tests

## Stage 2 — Docker / Containerization

* [x] Dockerfile
* [x] Non-root container user
* [x] Docker health check
* [x] `.dockerignore`
* [x] Local Docker build
* [x] Local container verification

## Stage 3 — GitHub Actions CI

* [x] GitHub Actions workflow
* [x] Python 3.12 CI environment
* [x] Dependency installation
* [x] Automated pytest execution
* [x] Pull request validation
* [x] Main branch validation

## Stage 4 — Docker Build in CI

* [x] Docker image build in GitHub Actions
* [x] Image tagged using Git commit SHA
* [x] CI verifies Docker build successfully

## Stage 5 — Security Scanning

* [x] Trivy integration
* [x] HIGH vulnerability scanning
* [x] CRITICAL vulnerability scanning
* [x] Secret scanning
* [x] Pipeline failure on detected blocking vulnerabilities

## Stage 6 — Container Registry

* [x] GitHub Container Registry integration
* [x] GitHub Actions authentication using `GITHUB_TOKEN`
* [x] Immutable SHA-based image tagging
* [x] Docker image publication to GHCR

## Stage 7 — Kubernetes

* [x] kind Kubernetes cluster
* [x] Kubernetes Deployment
* [x] Kubernetes Service
* [x] Multiple replicas
* [x] Readiness probes
* [x] Liveness probes
* [x] Rollout verification

## Stage 8 — Helm

* [x] Helm chart
* [x] Helm Deployment template
* [x] Helm Service template
* [x] Configurable values
* [x] Helm lint validation
* [x] Helm installation
* [x] Helm-managed Kubernetes resources
* [x] Helm release verification

## Stage 9 — Environment Separation

* [x] Development values file
* [x] Production values file
* [x] Environment-specific replica configuration
* [x] Separate Helm releases
* [x] Development deployment verification
* [x] Production deployment verification
* [x] Same immutable image deployed across environments

## Stage 10 — Automated Deployment

* [ ] Automated deployment from CI/CD
* [ ] Environment-aware deployment workflow
* [ ] Deployment after successful CI
* [ ] Kubernetes deployment automation

## Stage 11 — Rollback

* [ ] Deployment rollback strategy
* [ ] Helm rollback
* [ ] Version recovery
* [ ] Rollback verification

## Stage 12 — Observability / Final Production Pipeline

* [ ] Deployment observability
* [ ] Pipeline status visibility
* [ ] Final CI/CD workflow
* [ ] Production-style delivery workflow
* [ ] Final project documentation

---

# Current Status

**Completed through Stage 9 — Environment Separation.**

The project currently demonstrates:

```text
Source Code
    ↓
Pull Request
    ↓
GitHub Actions
    ↓
Automated Tests
    ↓
Docker Build
    ↓
Trivy Security Scan
    ↓
GHCR
    ↓
Kubernetes
    ↓
Helm
    ↓
Development / Production
```

The next objective is to automate the deployment process so that the CI/CD pipeline can promote a validated immutable image into the appropriate Kubernetes environment.
