# An unpredictable Terraform behavior sample

In this sample we use variable `db_names` as db names' source. It's a list of string and we use `count` to iterate it, and it's a terrible mistake.

We've defined three names in `terraform.tfvars`:

```hcl
db_names = [
  "api-db-for-demo",
  "app-db-for-demo",
  "backend-db-for-demo",
]
```

That will create three dbs. After apply, let's delete `app-db-for-demo` from the list:

```hcl
db_names = [
  "api-db-for-demo",
  //"app-db-for-demo",
  "backend-db-for-demo",
]
```

Then we execute `terraform plan`:

```shell
$ terraform plan

...


Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the last "terraform apply":

  # azurerm_postgresql_server.example[0] has changed
  ~ resource "azurerm_postgresql_server" "example" {
        id                                = "/subscriptions/xxx/resourceGroups/demo-for-unpredictable-behavior/provider
s/Microsoft.DBforPostgreSQL/servers/api-db-for-demo-myrttj"
        name                              = "api-db-for-demo-myrttj"
      + tags                              = {}
        # (17 unchanged attributes hidden)

        # (1 unchanged block hidden)
    }

  # azurerm_postgresql_server.example[1] has changed
  ~ resource "azurerm_postgresql_server" "example" {
        id                                = "/subscriptions/xxx/resourceGroups/demo-for-unpredictable-behavior/provider
s/Microsoft.DBforPostgreSQL/servers/app-db-for-demo-myrttj"
        name                              = "app-db-for-demo-myrttj"
      + tags                              = {}
        # (17 unchanged attributes hidden)

        # (1 unchanged block hidden)
    }

  # azurerm_postgresql_server.example[2] has changed
  ~ resource "azurerm_postgresql_server" "example" {
        id                                = "/subscriptions/xxx/resourceGroups/demo-for-unpredictable-behavior/provider
s/Microsoft.DBforPostgreSQL/servers/backend-db-for-demo-myrttj"
        name                              = "backend-db-for-demo-myrttj"
      + tags                              = {}
        # (17 unchanged attributes hidden)

        # (1 unchanged block hidden)
    }

  # azurerm_resource_group.example has changed
  ~ resource "azurerm_resource_group" "example" {
        id       = "/subscriptions/xxx/resourceGroups/demo-for-unpredictable-behavior"
        name     = "demo-for-unpredictable-behavior"
      + tags     = {}
        # (1 unchanged attribute hidden)
    }


Unless you have made equivalent changes to your configuration, or ignored the relevant attributes using ignore_changes, the following plan may include  
actions to undo or respond to these changes.

─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── 

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # azurerm_postgresql_server.example[1] must be replaced
-/+ resource "azurerm_postgresql_server" "example" {
      ~ fqdn                              = "app-db-for-demo-myrttj.postgres.database.azure.com" -> (known after apply)
      ~ id                                = "/subscriptions/xxx/resourceGroups/demo-for-unpredictable-behavior/provider
s/Microsoft.DBforPostgreSQL/servers/app-db-for-demo-myrttj" -> (known after apply)
      - infrastructure_encryption_enabled = false -> null
      ~ name                              = "app-db-for-demo-myrttj" -> "backend-db-for-demo-myrttj" # forces replacement
      ~ ssl_enforcement                   = "Enabled" -> (known after apply)
      - tags                              = {} -> null
        # (14 unchanged attributes hidden)

      ~ storage_profile {
          ~ auto_grow             = "Enabled" -> (known after apply)
          ~ backup_retention_days = 7 -> (known after apply)
          ~ geo_redundant_backup  = "Disabled" -> (known after apply)
          ~ storage_mb            = 5120 -> (known after apply)
        }
    }

  # azurerm_postgresql_server.example[2] will be destroyed
  # (because index [2] is out of range for count)
  - resource "azurerm_postgresql_server" "example" {
      - administrator_login               = "psqladmin" -> null
      - administrator_login_password      = (sensitive value)
      - auto_grow_enabled                 = true -> null
      - backup_retention_days             = 7 -> null
      - create_mode                       = "Default" -> null
      - fqdn                              = "backend-db-for-demo-myrttj.postgres.database.azure.com" -> null
      - geo_redundant_backup_enabled      = false -> null
      - id                                = "/subscriptions/xxx/resourceGroups/demo-for-unpredictable-behavior/provider
s/Microsoft.DBforPostgreSQL/servers/backend-db-for-demo-myrttj" -> null
      - infrastructure_encryption_enabled = false -> null
      - location                          = "eastus" -> null
      - name                              = "backend-db-for-demo-myrttj" -> null
      - public_network_access_enabled     = true -> null
      - resource_group_name               = "demo-for-unpredictable-behavior" -> null
      - sku_name                          = "B_Gen5_2" -> null
      - ssl_enforcement                   = "Enabled" -> null
      - ssl_enforcement_enabled           = true -> null
      - ssl_minimal_tls_version_enforced  = "TLSEnforcementDisabled" -> null
      - storage_mb                        = 5120 -> null
      - tags                              = {} -> null
      - version                           = "9.5" -> null

      - storage_profile {
          - auto_grow             = "Enabled" -> null
          - backup_retention_days = 7 -> null
          - geo_redundant_backup  = "Disabled" -> null
          - storage_mb            = 5120 -> null
        }
    }

Plan: 1 to add, 0 to change, 2 to destroy.

```

We just deleted one db name, but the plan want to destroy two dbs and create a new one as instead, why?

The key point is that we use `count`

```hcl
resource "azurerm_postgresql_server" "example" {
  count               = length(var.db_names)
  name                = "${var.db_names[count.index]}-${random_string.suffix.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
```

If we delete an element from middle of the list, the Terraform will delete the last db instance and try to update every db from the position where we delete the name. As `name` is a `ForceNew` argument of the resource, the plan will recreate every db instance from the position we just deleted the name. That's definitely not what we want, especially when we work with database.

The right way is to use `for_each` to avoid this embarrassed situation.
