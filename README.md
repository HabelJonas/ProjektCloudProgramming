# CloudProgramming

**Overview**
This repository contains a simple static web app packaged as a container image and deployed to Azure with Terraform. The infrastructure provisions Azure Container Apps in two regions and exposes them through Azure Front Door.

**Architecture**
- Static web app in `app/index.html` built into a Docker image via `Dockerfile`.
- Azure Container Registry (ACR) hosts the image.
- Two Azure Container Apps (primary and secondary regions) run the image.
- Azure Front Door routes global traffic to the regional apps.
- Shared observability components (Log Analytics and Container App Environments).

**Repo Layout**
- `app/index.html`: Static "Hello World" page.
- `Dockerfile`: Container image definition for the app.
- `infra/`: Terraform for Azure resources (ACR, Container Apps, Front Door, identities).
- `scripts/`: Local deployment helper scripts and their documentation.
- `docs/`: Project documentation, diagrams, and phase deliverables.

**Deployment**
- Local deployment script: see `scripts/README.md`.
- Infrastructure is managed with Terraform in `infra/`.
- CI/CD image build workflow lives in `.github/workflows/build-and-push.yml`.

**Documentation**
- Phase deliverables and diagrams are in `docs/`.
