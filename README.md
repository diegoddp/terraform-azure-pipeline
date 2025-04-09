# Terraform Deployment Pipeline

This repository contains a CI/CD pipeline for deploying infrastructure using Terraform on Azure. The pipeline is designed to automate the process of building, testing, and deploying your Terraform configurations.

## Repository Structure

```plaintext
├── azure-pipelines.yml
├── README.md
├── .gitignore
└── terraform
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── backend.tf
```
## Pipeline Overview
The pipeline is defined in the azure-pipelines.yml file and consists of two main stages:

1. Build Stage: Copies Terraform files to the artifact staging directory and publishes them as a build artifact.
2. Install Stage: Installs Terraform, downloads the build artifact, initializes Terraform, and applies the Terraform configuration.

## Prerequisites
- Azure DevOps account
- Azure subscription
- Terraform installed locally for testing

## Environment Variables
The pipeline uses several environment variables that should be securely stored in the Azure DevOps pipeline settings:

- ResourceGroupName
- AppServiceLocationName
- sqlhost
- administratorLogin
- administratorLoginPassword
- appinsightsname
- appservice_name
- serviceplanname
- tagenv
- skuname
- slots_prd_name
- databases_mysql_name_prd
- databases_mysql_name_uat
- storageacc
- container_prd
- container_uat
- azureSubsc

## main.tf 
The main.tf file is the primary configuration file for Terraform, defining the infrastructure resources to be deployed on Azure. It includes the following key components:

1. Terraform Provider Configuration:

  - Specifies the required provider (azurerm) and its version.
  - Configures the Azure provider with subscription, tenant, client IDs, and client secret.
2. Variable Definitions:

  - Defines various variables used throughout the configuration, such as resource group name, app service location, SQL host, and more.
  - Sensitive variables like azure_client_secret and administratorLoginPassword are marked as sensitive to ensure they are handled securely.
3. Resource Definitions:

- Resource Group: Creates an Azure resource group.
- Service Plan: Defines an Azure service plan for hosting web applications.
- Application Insights: Sets up Azure Application Insights for monitoring.
- Storage Account and Containers: Creates a storage account and containers for storing backups and other data.
- Linux Web App: Configures a Linux web app with various settings, including backups and app settings.
- Web App Slot: Defines a production slot for the web app.
- MySQL Flexible Server: Sets up a MySQL flexible server with configurations.
- MySQL Databases: Creates MySQL databases for production and UAT environments.
4. Data Sources:

- Retrieves a SAS token for the storage account to enable secure access.
5. Dependencies:

- Ensures resources are created in the correct order by specifying dependencies.

## Terraform Configuration
The Terraform configuration files are located in the terraform directory. The main configuration file is main.tf, and variables are defined in variables.tf. Outputs are defined in outputs.tf, and the backend configuration is in backend.tf.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.


  
