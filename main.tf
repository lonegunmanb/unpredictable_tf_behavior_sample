provider "azurerm" {
  features {}
}

variable "db_names" {
  type        = list(string)
  description = "Name list for postgres dbs"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  number  = false
  special = false
}

resource "azurerm_resource_group" "example" {
  name     = "demo-for-unpredictable-behavior"
  location = "eastus"
}

resource "azurerm_postgresql_server" "example" {
  count               = length(var.db_names)
  name                = "${var.db_names[count.index]}-${random_string.suffix.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}