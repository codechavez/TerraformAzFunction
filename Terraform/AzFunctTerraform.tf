##############################
# Variables
##############################

variable "resource_group_name" {
  type    = string
  default = "__app_name__Group" 
}

variable "location" {
  type    = string
  default = "westus2"
}

locals {
  full_rg_name      = "${terraform.workspace}-${var.resource_group_name}"
  full_app_name     = "${terraform.workspace}-__app_name__"
  app_storage_name  = __app_storage_name__
}

##############################
# BACKEND
##############################

terraform {
  backend "azurerm" {
    storage_account_name = __terra_storage_account_name__
    container_name       = __terra_storage_container_name__
    key                  = "${terraform.workspace}.terraform.tfstate"
    access_key           = __terra_storage_key__
  }
}

##############################
# Provider
##############################

provider "azurerm" {
  version = "~> 2.0"
  features {}
}

##############################
# RESOURCES
##############################

# Resource Group
resource "azurerm_resource_group" "app" {
  name = local.full_rg_name
  location = var.location

  tags = {
      environment = terraform.workspace
      system = "Demo"
  }
}

# Storage Account
resource "azurerm_storage_account" "app" {
  name                     = lower("${terraform.workspace}-appstorage${local.app_storage_name}")
  resource_group_name      = azurerm_resource_group.app.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
      environment = terraform.workspace
      system = "Demo"
  }
}

# Service Plan
resource "azurerm_app_service_plan" "app" {
  name                = lower("${local.full_app_name}-plan")
  location            = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags = {
    environment = terraform.workspace
    company     = "Demo"
  }
}

# Application Insights
resource "azurerm_application_insights" "app" {
  name                = "${local.full_app_name}-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  application_type    = "web"
  retention_in_days   = 90

   tags = {
    environment = terraform.workspace
    company     = "Demo"
  }
}

# Azure Function
resource "azurerm_function_app" "app" {
  name                  = local.full_app_name
  resource_group_name   = azurerm_resource_group.app.name
  location              = var.location
  app_service_plan_id   = azurerm_app_service_plan.app.id
  storage_account_name  = azurerm_storage_account.app.name
  storage_account_access_key = azurerm_storage_account.app.primary_access_key
  version = "~3"

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.app.instrumentation_key}",
    "WEBSITE_TIME_ZONE"              = "Pacific Standard Time"
  }

  tags = {
    environment = terraform.workspace
    company     = "Demo"
  }
}