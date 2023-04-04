resource "random_id" "storage_container_suffix" {
  byte_length = 4
}

resource "azurerm_storage_account" "prefect-logs" {
  name                = "${var.storage_account_name}${random_id.storage_container_suffix.hex}"
  resource_group_name = azurerm_resource_group.rg.name

  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

resource "azurerm_storage_container" "prefect-logs" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.prefect-logs.name
  container_access_type = "private"
}