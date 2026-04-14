---
name: terraform
description: Terraform infrastructure agent for managing cloud infrastructure as code
version: 1.0.0
tags: [terraform, infrastructure, cloud, iac]
---

# Terraform Standards

## Purpose
Ensure infrastructure is defined, managed, and deployed in a consistent, secure, and scalable way using Terraform.

Infrastructure must be:

- reproducible
- version-controlled
- predictable
- safe to change
- aligned with application architecture

---

## Core Principles

### 1. Infrastructure as Source of Truth
Terraform is the single source of truth for infrastructure.

- do not manually modify resources in production
- do not rely on console-driven changes
- all infrastructure must be declared and versioned

---

### 2. Idempotency
Terraform runs should produce the same result every time.

- no side effects
- no unpredictable behavior
- no reliance on execution order hacks

---

### 3. Declarative Over Imperative
Define *what* the infrastructure should be, not *how* to create it.

---

### 4. Safe Change Management
Infrastructure changes must be:

- reviewable
- predictable
- reversible

---

### 5. Least Privilege
Infrastructure should enforce minimal access by default.

---

## Project Structure

### Recommended Layout

/infra
/modules
/vpc
/ecs
/rds
/alb
/dev
main.tf
variables.tf
outputs.tf
/staging
/prod

---

## Environment Separation

Each environment must be isolated:

- separate state files
- separate resources where required
- no shared mutable state across environments

### Rules

- dev, staging, and prod must not overlap
- production must not depend on dev resources
- environment-specific values must be configurable

---

## State Management

## Rules

- use remote state (e.g., S3 + DynamoDB locking)
- never commit state files to version control
- enable state locking
- restrict access to state storage

### Security

- state files may contain sensitive data
- restrict access using IAM
- encrypt state at rest

---

## Modules

## Purpose
Promote reuse and consistency.

### Rules

- create reusable modules for common patterns
- keep modules focused and single-purpose
- avoid overly generic modules
- define clear inputs and outputs
- version modules where appropriate

### Examples

- VPC module
- ECS service module
- RDS module
- ALB module

---

## Naming Conventions

### Rules

- use consistent naming across all resources
- include environment and service context

Example:
app-prod-api-alb
app-dev-postgres

- avoid random or ambiguous names
- prefer readability over brevity

---

## Variables and Configuration

### Rules

- define all configurable values as variables
- avoid hardcoding values
- use sensible defaults where appropriate
- document variables clearly

### Sensitive Variables

- mark secrets as sensitive
- never log or output sensitive values
- use secret managers where possible

---

## Outputs

### Rules

- expose only necessary outputs
- do not expose secrets
- use outputs for cross-module communication

---

## Resource Management

### Rules

- tag all resources
- define lifecycle rules explicitly when needed
- avoid orphaned resources
- ensure cleanup paths exist

---

## Tagging Standards

All resources must include tags:

- environment (dev, staging, prod)
- service or application name
- owner (team or system)
- cost allocation tag

Example:

```tags = {
Environment = “prod”
Service     = “job-board”
Owner       = “platform”
}```

---

## Security Standards

### Rules

- restrict security group rules to least privilege
- avoid open ports (0.0.0.0/0) unless necessary
- keep databases in private subnets
- enforce encryption where supported
- use IAM roles instead of static credentials

---

## Networking Standards

### Rules

- separate public and private subnets
- place ALBs in public subnets
- place compute (ECS, services) in private subnets
- restrict outbound access where possible
- use NAT gateways only when required

---

## Secrets Management

### Rules

- do not store secrets in Terraform code
- use AWS Secrets Manager or SSM
- reference secrets dynamically
- avoid exposing secrets in outputs or logs

---

## Plan and Apply Workflow

### Rules

- always run `terraform plan` before apply
- review changes before applying
- do not apply blindly
- use CI/CD pipelines for production changes

---

## CI/CD Integration

### Requirements

- automated plan generation
- manual approval for production applies
- consistent environment deployment flow
- audit trail of changes

---

## Drift Management

### Rules

- detect infrastructure drift regularly
- reconcile drift through Terraform
- do not manually “fix” drift in production without updating code

---

## Dependency Management

### Rules

- use explicit dependencies where needed
- avoid implicit coupling
- avoid circular dependencies

---

## Lifecycle Rules

Use lifecycle blocks carefully:

- prevent_destroy for critical resources
- ignore_changes only when justified

Avoid masking real changes.

---

## Scaling and Resilience

### Rules

- design for high availability where required
- distribute across availability zones
- avoid single points of failure
- configure autoscaling where appropriate

---

## Cost Awareness

### Rules

- avoid unnecessary resources
- clean up unused infrastructure
- monitor cost-impacting resources
- right-size instances and services

---

## Documentation

### Rules

- document module purpose
- document variables and outputs
- explain non-obvious design decisions

---

## Review Checklist

Before applying changes:

- Is the plan reviewed?
- Are resources named correctly?
- Are tags applied?
- Are security rules restricted?
- Are secrets handled securely?
- Is state managed properly?
- Are environments isolated?
- Is this change safe to apply?
- Is rollback possible?

---

## Anti-Patterns to Avoid

Do not:

- manually change infrastructure in the console
- hardcode secrets
- use overly broad security rules
- create giant, unmaintainable modules
- skip plan review
- reuse state across environments
- ignore drift
- create hidden dependencies

---

## Goal
Build infrastructure that is:

- predictable
- secure
- scalable
- easy to understand
- safe to evolve

Infrastructure should be as reliable and maintainable as application code.
