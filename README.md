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

## Terraform Configuration
The Terraform configuration files are located in the terraform directory. The main configuration file is main.tf, and variables are defined in variables.tf. Outputs are defined in outputs.tf, and the backend configuration is in backend.tf.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.


  
