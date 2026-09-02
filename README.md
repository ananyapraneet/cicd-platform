# CI/CD Platform

A DevOps-focused project demonstrating a complete CI/CD platform for building, securing, publishing, deploying, verifying, and promoting a containerized application to Kubernetes.

The application itself is intentionally simple. The primary objective of this project is to demonstrate the engineering practices surrounding:

* CI/CD
* Containerization
* Security scanning
* Immutable artifact management
* GitHub Container Registry
* Kubernetes
* Helm
* Environment separation
* Automated deployment
* Deployment verification
* Rollback
* Production approval gates
* Operational visibility

The delivery platform is the product.

---

## Architecture

The platform uses different paths for pull requests and merged changes.

### Pull Request Flow

Pull requests validate the application and container before they can be merged.

```text
Developer
    ↓
Feature Branch
    ↓
Pull Request
    ↓
GitHub Actions
    ↓
Run Tests
    ↓
Build Docker Image
    ↓
Trivy Security Scan
    ↓
STOP
```

Pull requests do **not** publish images to GHCR and do **not** deploy to Kubernetes.

### Main Branch Flow

After a pull request is merged into `main`, the validated commit goes through the delivery pipeline.

```text
Merge to main
    ↓
GitHub Actions CI
    ↓
Run Tests
    ↓
Build Docker Image
    ↓
Trivy Security Scan
    ↓
Push Image to GHCR
    ↓
Deploy Development
    ↓
Kubernetes Rollout Verification
    ↓
Verify Running Image
    ↓
Application /health Verification
    ↓
Production Approval Gate
    ↓
Deploy Production
    ↓
Kubernetes Rollout Verification
    ↓
Verify Running Image
    ↓
Application /health Verification
```

### Immutable Artifact Flow

The project follows an immutable artifact model:

```text
Git Commit SHA
      ↓
Docker Image
      ↓
Trivy Scan
      ↓
GHCR
      ↓
Development
      ↓
Production
```

The same Git commit SHA is used throughout the pipeline.

The Docker image is not rebuilt between environments.

Images are identified using the Git commit SHA rather than mutable tags such as `latest`.

This provides traceability between source code, container image, and Kubernetes deployment.

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
* Bash

---

# Application

The application is intentionally minimal because the primary focus is the DevOps platform surrounding it.

## Endpoints

### `GET /`

Returns a simple application message.

Example:

```json
{
  "message": "CI/CD Platform API"
}
```

### `GET /health`

Returns the application health status.

Example:

```json
{
  "status": "healthy"
}
```

The `/health` endpoint is used by:

* Docker health checks
* Kubernetes readiness probes
* Kubernetes liveness probes
* Deployment verification

---

# Project Structure

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
├── scripts/
│   ├── deploy.sh
│   └── rollback.sh
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
│
├── Dockerfile
├── .dockerignore
├── .gitignore
├── requirements.txt
├── LICENSE
└── README.md
```

---

# CI/CD Pipeline

The CI/CD platform is implemented using GitHub Actions.

## Pull Request Pipeline

Pull requests targeting `main` execute:

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
STOP
```

No image is published and no deployment occurs from a pull request.

This prevents unmerged code from reaching the deployment environments.

## Main Branch Pipeline

After a pull request is merged into `main`:

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
Tag image using Git SHA
   ↓
Push image to GHCR
```

The resulting immutable image is then used by the deployment workflow.

---

# Testing

The application contains automated tests for:

* Root endpoint
* Health endpoint

Tests are executed using:

```bash
python -m pytest -v
```

The same test suite is executed by GitHub Actions.

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

Unfixed vulnerabilities are ignored to prevent known-but-unfixable issues from blocking the pipeline.

The Trivy scan must pass before the image can be published to GHCR.

The pipeline therefore follows:

```text
Build
  ↓
Security Scan
  ↓
Push
```

rather than pushing an image before scanning it.

---

# Container Registry

Docker images are published to **GitHub Container Registry (GHCR)**.

Image format:

```text
ghcr.io/ananyapraneet/cicd-platform:<git-sha>
```

Example:

```text
ghcr.io/ananyapraneet/cicd-platform:fcb3656c56d9dee89393b7328734836c48d3f033
```

The GitHub Actions workflow authenticates to GHCR using the GitHub-provided `GITHUB_TOKEN`.

The pipeline does not depend on the mutable `latest` tag.

Using the Git commit SHA provides:

* Immutable image identification
* Deployment traceability
* Reproducible artifact references
* Clear rollback targets

---

# Kubernetes

The application is deployed to Kubernetes using a local `kind` cluster for development and platform testing.

Cluster context:

```text
kind-cicd-platform
```

The application runs as a Kubernetes Deployment with:

* Multiple replicas
* Readiness probes
* Liveness probes
* ClusterIP Service
* Rolling deployments

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

Example:

```bash
helm upgrade --install cicd-platform-dev helm/cicd-platform \
  -f helm/cicd-platform/values.yaml \
  -f helm/cicd-platform/values-dev.yaml \
  --set image.tag=<git-sha>
```

Helm release names allow multiple environments to coexist in the same Kubernetes cluster.

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

Both environments use the same immutable Docker image identified by the Git commit SHA when a release is promoted.

This demonstrates environment-specific configuration without duplicating Kubernetes templates.

---

# Automated Deployment

Deployment automation is implemented using GitHub Actions and a self-hosted GitHub Actions runner.

The self-hosted runner is required because the Kubernetes cluster is a local `kind` cluster running on the development machine.

The deployment workflow is triggered after the `CI` workflow successfully completes for `main`.

```text
main
 ↓
CI succeeds
 ↓
Deploy Development
```

The deployment workflow checks out the exact commit that triggered the successful CI run:

```text
github.event.workflow_run.head_sha
```

That same SHA is passed to the deployment script as the Docker image tag.

---

# Deployment Script

Development and production deployments use:

```text
scripts/deploy.sh
```

Usage:

```bash
./scripts/deploy.sh <dev|prod> <image-tag>
```

Example:

```bash
./scripts/deploy.sh dev fcb3656c56d9dee89393b7328734836c48d3f033
```

The script:

1. Validates the environment
2. Selects the environment-specific Helm values
3. Deploys the specified image using Helm
4. Waits for the Kubernetes rollout
5. Displays deployment status
6. Displays the exact image running in Kubernetes
7. Displays running pods
8. Creates a temporary port-forward
9. Verifies the application `/health` endpoint
10. Fails the deployment if application health cannot be verified

This provides both Kubernetes-level and application-level deployment verification.

---

# Deployment Observability

The deployment process exposes useful operational information in the deployment logs.

After a deployment, the pipeline reports:

```text
Deployment rollout successful.
```

The currently deployed image is also displayed:

```text
Current image:
ghcr.io/ananyapraneet/cicd-platform:<git-sha>
```

Running pods are displayed:

```text
Running pods:
...
```

Finally, the application health endpoint is verified:

```text
{"status":"healthy"}

Application health check passed.
Deployment verification successful.
```

The health verification includes retry logic to account for temporary startup delays while the Kubernetes Service port-forward becomes available.

---

# Production Deployment Gate

Production deployment is protected using a GitHub Actions `production` environment.

The production job:

* Runs only after development deployment succeeds
* Uses the same immutable image SHA deployed to development
* Requires approval through the GitHub production environment
* Does not rebuild the Docker image

The production flow is therefore:

```text
Deploy Development
        ↓
Health Verification
        ↓
Production Environment
        ↓
Manual Approval
        ↓
Deploy Production
        ↓
Health Verification
```

This provides a production-style promotion model where a successfully deployed development artifact must be explicitly approved before production deployment.

---

# Rollback

Rollback is managed using Helm release history.

Each Helm upgrade creates a new revision.

Example:

```bash
helm history cicd-platform-dev
```

A previous revision can be restored using:

```bash
helm rollback cicd-platform-dev <revision>
```

The project also provides a rollback helper script:

```text
scripts/rollback.sh
```

Usage:

```bash
./scripts/rollback.sh <dev|prod> <revision>
```

Example:

```bash
./scripts/rollback.sh dev 3
```

The script:

1. Validates the environment
2. Validates the revision number
3. Performs the Helm rollback
4. Waits for Kubernetes rollout completion
5. Displays the restored image
6. Displays the current pods

Rollback was tested using a controlled invalid image deployment.

The deployment was intentionally changed to an invalid image:

```text
this-image-does-not-exist
```

Kubernetes produced an unhealthy `ErrImagePull` pod.

The Helm release was then rolled back to a known-good revision, restoring the previous working image and healthy pod.

This demonstrates that rollback is not only configured but operationally verified.

---

# Immutable Promotion Model

The project intentionally avoids rebuilding images between environments.

For example:

```text
Commit:
fcb3656...
      ↓
GHCR:
cicd-platform:fcb3656...
      ↓
Development:
cicd-platform-dev
      ↓
Approval
      ↓
Production:
cicd-platform-prod
```

The image remains the same throughout the promotion process.

This reduces the possibility of development and production running different artifacts from the same source change.

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
* [x] Images published only from `main`

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

* [x] Automated deployment from CI/CD
* [x] Environment-aware deployment workflow
* [x] Deployment after successful CI
* [x] Self-hosted GitHub Actions runner
* [x] Kubernetes deployment automation
* [x] Immutable SHA-based deployment

## Stage 11 — Rollback

* [x] Deployment rollback strategy
* [x] Helm rollback
* [x] Version recovery
* [x] Rollback helper script
* [x] Invalid-image failure test
* [x] Rollback verification

## Stage 12 — Observability / Final Production Pipeline

* [x] Deployment rollout verification
* [x] Running pod visibility
* [x] Deployed image visibility
* [x] Application `/health` verification
* [x] Health-check retry logic
* [x] Production deployment environment
* [x] Production approval gate
* [x] Production deployment
* [x] Final CI/CD workflow
* [x] Final project documentation

---

# Final Pipeline

The completed platform provides the following delivery flow:

```text
                         ┌─────────────────────────────┐
                         │       Pull Request          │
                         └──────────────┬──────────────┘
                                        ↓
                                  Run Tests
                                        ↓
                                  Docker Build
                                        ↓
                                 Trivy Scan
                                        ↓
                                      STOP
                                        │
                                      MERGE
                                        ↓
                                      main
                                        ↓
                                  Run Tests
                                        ↓
                                  Docker Build
                                        ↓
                                 Trivy Scan
                                        ↓
                                  Push to GHCR
                                        ↓
                              Deploy Development
                                        ↓
                             Rollout Verification
                                        ↓
                              Image Verification
                                        ↓
                            Application Health Check
                                        ↓
                              Production Approval
                                        ↓
                              Deploy Production
                                        ↓
                             Rollout Verification
                                        ↓
                              Image Verification
                                        ↓
                            Application Health Check
```

Rollback remains available through Helm:

```text
Production / Development
          ↓
     Helm History
          ↓
    Known-good Revision
          ↓
     Helm Rollback
          ↓
 Rollout Verification
          ↓
   Image Verification
```

---

# Current Status

**Project completed through Stage 12 — Observability / Final Production Pipeline.**

The project now demonstrates a complete DevOps delivery platform:

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
Development Deployment
    ↓
Kubernetes Rollout
    ↓
Image Verification
    ↓
Application Health Verification
    ↓
Production Approval
    ↓
Production Deployment
    ↓
Kubernetes Rollout
    ↓
Application Health Verification
```

The platform also provides:

```text
Immutable SHA-based artifacts
        +
Environment separation
        +
Automated deployment
        +
Deployment verification
        +
Production approval
        +
Helm rollback
```

The application remains intentionally simple so that the engineering focus stays on the CI/CD and delivery platform.
