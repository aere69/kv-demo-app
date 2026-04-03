# kv-demo-app

## Dockerized Sample App (Terraform + GitHub Actions + Dockerized App + Azure Key Vault + Managed Identity + ACR + App Service)

Complete Dockerized FastAPI app that authenticates to Azure Key Vault using managed identity (or Azure CLI when running locally). It’s intentionally minimal, the focus is on the DevSecOps patterns rather than framework complexity.

This is a clean, modern DevSecOps pattern that avoids service principal secrets, avoids storing secrets in Terraform, and uses Key Vault + managed identity end‑to‑end.

## Terraform + GitHub Actions

- Terraform deploys App Service / Container Apps
- GitHub Actions builds & pushes the container
- GitHub Actions deploys it
- Managed identity automatically grants Key Vault access

## Implementation

### 🧱 1. Terraform Infrastructure: Infra + Key Vault + ACR + Web App (managed identity)

This Terraform config deploys:

- Resource Group
- Azure Key Vault (RBAC mode)
- Secret placeholder
- Azure Container Registry (ACR)
- App Service Plan
- Linux Web App (container) with system‑assigned managed identity
- RBAC:
  - App → Key Vault Secrets User
  - App → ACR Pull

See file [main.tf](main.tf)

### 🐳 2. Dockerized App (FastAPI + Key Vault)

2.1 🧠 [app.py](app.py) — FastAPI app that reads a secret from Azure Key Vault

- `DefaultAzureCredential` is the **DevSecOps best practice** because:
  - Locally → uses Azure CLI or VS Code identity
  - In Azure → uses **managed identity**
- No secrets in code, config, or Docker image
- Only environment variables define:
  - Key Vault URL
  - Secret name

2.2 📦 [requirements.txt](requirements.txt)

Pinned versions make the workshop reproducible.

2.3 🐳 [Dockerfile](Dockerfile)

- `python:3.11-slim` keeps the image small
- No secrets baked into the image
- Container expects environment variables at runtime

2.4 🧪 Local testing (with Azure CLI identity)

See [local-test.sh](local-test.sh)

`DefaultAzureCredential` behaves differently locally vs in Azure.

To run local test:

- `http://localhost:8000/health`
- `http://localhost:8000/secret`

### 3. GitHub Actions: build, push, deploy container + Terraform apply

See [deploy.yml](.github/workflows/deploy.yml)

GitHub secrets needed:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `DB_PASSWORD`

### 4. How this ties together

- Terraform:
  - Defines Key Vault, ACR, Web App, managed identity, RBAC.
  - Never contains real secret values in code — `db_password` comes from pipeline.
- GitHub Actions:
  - Uses OIDC to Azure (no stored SP secrets).
  - Passes `DB_PASSWORD` from GitHub Secrets → Terraform → Key Vault.
  - Builds Docker image, pushes to ACR, points Web App at that image.
- App (in container):
  - Uses DefaultAzureCredential + managed identity to read Key Vault.
  - No secrets in code, image, or repo—only in:
    - GitHub encrypted secrets
    - Key Vault
