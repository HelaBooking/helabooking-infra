# Helabooking-Infra Repo

Infrastructure as Code (IaC) and documentation repository for the helabooking project, enabling automated provisioning, configuration, and management of its on-prem & cloud infrastructure.

## Folder Structure

    helabooking-infra
    ├── _docs/                      # Documentation related to setting up and managing infrastructure
    │   ├── cloud/                  # Cloud infrastructure documentation
    │   ├── on-prem/                # On-premises infrastructure documentation
    │   └── project-task/           # Step-by-step guides for specific project tasks
    ├── ansible/                    # Ansible playbooks and roles for Cloud K8s cluster setup
    ├── cloud/                      # AWS infrastructure provisioning and cluster workload provisioning terraform files
    │   ├── cluster-configs/        # Authentication and access files (e.g., kube-config)
    │   ├── cluster-templates/      # Reusable Terraform modules for AWS Related K8s resources
    │   ├── jenkins-jobs/           # Jenkins CI/CD pipeline configurations
    │   ├── management/             # Infrastructure state and config for shared management services
    │   ├── env-stage/              # Infrastructure state and config for Staging environment
    │   └── env-prod/               # Infrastructure state and config for Production environment
    ├── on-prem/                    # On-premises cluster workload provisioning terraform files
    │   ├── cluster-configs/        # Authentication and access files (e.g., kube-config)
    │   ├── cluster-templates/      # Reusable Terraform modules for On-Prem K8s resources
    │   ├── jenkins-jobs/           # Jenkins CI/CD pipeline configurations
    │   ├── management/             # Infrastructure state and config for shared management services
    │   |── env-dev/                # Infrastructure state and config for Development environment
    |   └── env-qa/                 # Infrastructure state and config for QA environment
    └── README.md                   # Project overview and setup instructions

> Due to Resource constraints, `env-qa` will not be setup initially. It can be setup later when more resources are available.

## Getting Started

To get started with the helabooking-infra repository, refer to the documentation in the `_docs` folder.
