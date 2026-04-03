terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

variable "name_prefix" {
  default = "demokvapp" # must be lowercase, no hyphens for ACR
}

variable "location" {
  default = "westeurope"
}

variable "db_password" {
  type      = string
  sensitive = true
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${var.name_prefix}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
  enable_rbac_authorization   = true
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.kv.id
}

# ACR
resource "azurerm_container_registry" "acr" {
  name                = "${var.name_prefix}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "${var.name_prefix}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Web App (container, identity)
resource "azurerm_linux_web_app" "app" {
  name                = "${var.name_prefix}-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    KEYVAULT_URL            = azurerm_key_vault.kv.vault_uri
    DB_PASSWORD_SECRET_NAME = "db-password"
    WEBSITES_PORT           = "8000"
  }
}

# App → Key Vault secrets
resource "azurerm_role_assignment" "app_kv_reader" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

# App → ACR pull
resource "azurerm_role_assignment" "app_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "app_name" {
  value = azurerm_linux_web_app.app.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
