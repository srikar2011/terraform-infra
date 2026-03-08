# Architecture Decisions

## Single root module with tfvars per environment
Instead of separate environment folders, we use a single root
module and pass environment-specific values via tfvars files.
This is the enterprise pattern - one codebase, many environments.
The deploy pipeline passes -var-file=tfvars/dev.tfvars at plan time.

## Why modules
Each module owns one concern - security, compute, loadbalancer.
A change to the security module applies consistently across all
environments. Modules are versioned via Git tags in later stages.

## Why S3 backend with DynamoDB locking
Jenkins cleans workspace after every build. Without remote state,
partial applies left orphaned AWS resources with no way to destroy
them. DynamoDB prevents concurrent pipeline runs corrupting state.

## Instance type per environment
dev:     t2.micro  - free tier eligible, cost control
int/qa:  t2.small  - slightly more for integration testing
prod:    t3.medium  - consistent performance, burstable

## Database not deployed in dev by default
RDS costs money even when idle. In dev the database module
is commented out in main.tf until database learning begins.