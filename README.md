# CI/CD Platform

A DevOps-focused project demonstrating a complete CI/CD platform for deploying a containerized application to Kubernetes.

The project focuses on automation, software delivery, security, deployment strategies, and environment management rather than application complexity.

## Planned Architecture

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
Container Registry
    ↓
Kubernetes
    ↓
Application

## Planned Technologies

- Python
- FastAPI
- Git
- GitHub
- GitHub Actions
- Docker
- Container Registry
- Kubernetes
- Helm
- Security Scanning

## Environments

- Development
- Staging
- Production

## Project Goals

- Implement automated CI
- Build and publish Docker images
- Scan container images for vulnerabilities
- Deploy applications to Kubernetes
- Manage deployments using Helm
- Separate development, staging, and production environments
- Implement automated deployment
- Demonstrate deployment rollback

## Application

The application is intentionally simple. The primary objective of this project is to demonstrate the CI/CD and DevOps platform surrounding the application.

### Endpoints

`GET /`

Returns a simple application message.

`GET /health`

Returns the application health status.

## Project Status

Stage 1 — Application + Repository

- [x] Simple FastAPI application
- [x] Git repository
- [x] GitHub repository
- [x] Initial README
- [x] Docker
- [ ] CI pipeline
- [ ] Security scanning
- [ ] Container registry
- [ ] Kubernetes
- [ ] Helm
- [ ] Automated deployment
- [ ] Rollback strategy
- [ ] Environment separation
