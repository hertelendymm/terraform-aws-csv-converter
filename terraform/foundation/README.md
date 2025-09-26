# Creating the foundation for the csv-to-json converter project

This configuration creates the founadtional resources for the Terraform remote state 
It should be aplied MANUALLY ONE TIME. After providing the S3 and the DynamoDB names to the terraform/variables.tf, the main pipeline can access and use the created AWS resources for the rest of the project.