
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.58.0"
    }
  }
}


variable "azure_client_secret" {
  description = "Azure Client Secret from Variable Group"
  type        = string
  sensitive   = true

}

provider "azurerm" {
  subscription_id = "your_actual_subscription_id"
  tenant_id = "your_actual_tenant_id"
  client_id = "your_actual_client_id"
  client_secret = var.azure_client_secret
  features {
    
  }
  skip_provider_registration = true

}


variable "ResourceGroupName" {
  description = "The name of the resource group"
  type        = string
}

variable "AppServiceLocationName" {
  description = "Location for the App Service"
  type        = string
}

variable "slots_prd_name" {

  description = "Name of the production slot"
  type        = string
  default     = "prd"

}



variable "databases_mysql_name_prd" {

  description = "MySQL database name for production"
  type        = string
  default     = "mysqldbprd"

}



variable "sqlhost" {
  description = "SQL host name"
  type        = string
}

variable "storageacc" {
  description = "storage account name"
  type        = string
  default = "storageaccblobkerry"

}



variable "container_prd" {
  description = "storage account name"
  type        = string
  default = "prd-container"

}



variable "container_uat" {
  description = "storage account name"
  type        = string
  default = "uat-container"



}

variable "databases_mysql_name_uat" {
  description = "MySQL database name for UAT"
  type        = string
}

variable "administratorLogin" {
  description = "Administrator login for the database"
  type        = string
}

variable "administratorLoginPassword" {
  description = "Administrator password for the database"
  type        = string
  sensitive   = true
}

variable "appservice_name" {
  description = "App service name"
  type        = string
}

variable "serviceplanname" {
  description = "Service plan name"
  type        = string
}

variable "tagenv" {
  description = "Tag for environment"
  type        = string
}

variable "appinsightsname" {
  description = "App Insights name"
  type        = string
}

variable "skuname" {
  description = "SKU name for the service"
  type        = string
}



resource "azurerm_resource_group" "rg" {
  name     = var.ResourceGroupName
  location = var.AppServiceLocationName
}

resource "azurerm_service_plan" "terraformazure" {
  name                = var.serviceplanname
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.skuname


}

resource "azurerm_application_insights" "example" {
  name                = var.appinsightsname
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"

}



resource "azurerm_application_insights_smart_detection_rule" "example" {
  name                     = "Degradation in server response time"
  application_insights_id  = azurerm_application_insights.example.id
  enabled                  = true
  send_emails_to_subscription_owners = true

  depends_on = [
    azurerm_application_insights.example
  ]

}
resource "azurerm_storage_account" "storageaccblob" {
  name                     = var.storageacc
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

   depends_on = [    
    azurerm_resource_group.rg
  ]
}

resource "azurerm_storage_container" "prd" {
  name                  = var.container_prd
  storage_account_name  = azurerm_storage_account.storageaccblob.name
  container_access_type = "private"

}

resource "azurerm_storage_container" "uat" {
  name                  = var.container_uat
  storage_account_name  = azurerm_storage_account.storageaccblob.name
  container_access_type = "private"
}

data "azurerm_storage_account_sas" "example" {
  connection_string = azurerm_storage_account.storageaccblob.primary_connection_string
  resource_types {
    service   = true
    container = true
    object    = true
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = "${formatdate("YYYY-MM-DD", timestamp())}T${formatdate("HH:mm:ssZ", timestamp())}"
  expiry = "${formatdate("YYYY-MM-DD", timeadd(timestamp(), "8760h"))}T${formatdate("HH:mm:ssZ", timeadd(timestamp(), "8760h"))}"

  permissions {
    read    = true
    write   = true
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false

  }

}



resource "azurerm_linux_web_app" "newappazureterraform" {
  name                = var.appservice_name
  resource_group_name = var.ResourceGroupName
  location            = var.AppServiceLocationName
  service_plan_id     = azurerm_service_plan.terraformazure.id
  client_affinity_enabled = "true"
  https_only = "true"

  site_config {
    always_on              = "false"
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    app_command_line       = "cp /home/default /etc/nginx/sites-enabled/default; service nginx restart"  # Your startup command
    application_stack {

      php_version = "8.2"
    }

  }

  backup {
    name                 = "Custom Backup"
    storage_account_url  = "https://${azurerm_storage_account.storageaccblob.name}.blob.core.windows.net/${azurerm_storage_container.uat.name}?${data.azurerm_storage_account_sas.example.sas}&sr=b"

    schedule {
      frequency_interval = 1
      frequency_unit     = "Day"
      keep_at_least_one_backup = true
      start_time         = "2023-02-18T09:00:00Z"      
    }
  }
  lifecycle {

    ignore_changes = [backup]

  }

  app_settings = {

      WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
      DATABASE_HOST                       = "${var.sqlhost}.mysql.database.azure.com"
      DATABASE_NAME                       = var.databases_mysql_name_uat
      DATABASE_PASSWORD                   = var.administratorLoginPassword
      DATABASE_USERNAME                   = "${var.administratorLogin}"
      MYSQL_SSL_CA                        = "D:\\home\\site\\bin\\DigiCertGlobalRootCA.crt.pem"

    }

    connection_string {
      name  = "defaultConnection"
      type  = "MySql"
      value = "Database=${var.databases_mysql_name_uat};Data Source=${var.sqlhost}.mysql.database.azure.com;User Id=${var.administratorLogin};Password=${var.administratorLoginPassword}"

}

   depends_on = [
    azurerm_service_plan.terraformazure
  ]
}

resource "azurerm_linux_web_app_slot" "prd_slot" {
  name           = var.slots_prd_name
  app_service_id = azurerm_linux_web_app.newappazureterraform.id

  site_config {
    always_on              = "false"
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    app_command_line       = "cp /home/default /etc/nginx/sites-enabled/default; service nginx restart"  # Your startup command
  }
  backup {
    name                 = "Custom Backup"
    storage_account_url  = "https://${azurerm_storage_account.storageaccblob.name}.blob.core.windows.net/${azurerm_storage_container.prd.name}?${data.azurerm_storage_account_sas.example.sas}&sr=b"
    schedule {
      frequency_interval = 1
      frequency_unit     = "Day"
      keep_at_least_one_backup = true
      start_time         = "2023-02-18T09:00:00Z"
    }

  }

    lifecycle {
    ignore_changes = [backup]

  }
    app_settings = {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = "true"
      DATABASE_HOST                       = "${var.sqlhost}.mysql.database.azure.com"
      DATABASE_NAME                       = var.databases_mysql_name_prd
      DATABASE_PASSWORD                   = var.administratorLoginPassword
      DATABASE_USERNAME                   = "${var.administratorLogin}"
      MYSQL_SSL_CA                        = "D:\\home\\site\\bin\\DigiCertGlobalRootCA.crt.pem"

    }
    connection_string {
      name  = "defaultConnection"
      type  = "MySql"
      value = "Database=${var.databases_mysql_name_prd};Data Source=${var.sqlhost}.mysql.database.azure.com;User Id=${var.administratorLogin};Password=${var.administratorLoginPassword}"

}

}

resource "azurerm_mysql_flexible_server" "mysqlserverterraformazure" {
  name                = var.sqlhost
  resource_group_name = var.ResourceGroupName
  location            = var.AppServiceLocationName
  administrator_login = var.administratorLogin
  administrator_password = var.administratorLoginPassword
  sku_name            = "B_Standard_B1ms"
  version             = "8.0.21"
   storage {
    size_gb          = 50  
    auto_grow_enabled = true  
    iops             = 450  

  }

  depends_on = [
    azurerm_resource_group.rg
  ]

}



resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = var.ResourceGroupName
  server_name         = azurerm_mysql_flexible_server.mysqlserverterraformazure.name
  value               = "ON"

}

resource "azurerm_mysql_flexible_server_configuration" "tls_version" {
  name                = "tls_version"
  resource_group_name = var.ResourceGroupName
  server_name         = azurerm_mysql_flexible_server.mysqlserverterraformazure.name
  value               = "TLSv1.2,TLSv1.3"

}

resource "azurerm_mysql_flexible_server_configuration" "sql_mode" {
  name                = "sql_mode"
  resource_group_name = var.ResourceGroupName
  server_name         = azurerm_mysql_flexible_server.mysqlserverterraformazure.name
  value               = ""

}

resource "azurerm_mysql_flexible_server_configuration" "sql_generate_invisible_primary_key" {
  name                = "sql_generate_invisible_primary_key"
  resource_group_name = var.ResourceGroupName
  server_name         = azurerm_mysql_flexible_server.mysqlserverterraformazure.name
  value               = "OFF"
}


resource "azurerm_mysql_flexible_database" "appdb" {
  name                = var.databases_mysql_name_uat
  resource_group_name = var.ResourceGroupName
  server_name         = azurerm_mysql_flexible_server.mysqlserverterraformazure.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_general_ci"


  depends_on = [
    azurerm_mysql_flexible_server.mysqlserverterraformazure

  ]

}





resource "azurerm_mysql_flexible_database" "prd_db" {  
  name                = var.databases_mysql_name_prd
  resource_group_name = var.ResourceGroupName
  server_name         = azurerm_mysql_flexible_server.mysqlserverterraformazure.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_general_ci"

  depends_on = [
    azurerm_mysql_flexible_server.mysqlserverterraformazure

  ]

}
