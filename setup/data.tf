data "external" "client_ip" {
  program = ["bash", "-c", "curl -s https://api.ipify.org?format=json"]
}

data "azurerm_client_config" "current" {}
