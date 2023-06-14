locals {
  org_name = replace(replace(var.org, "/[ -]/", "_"), "/\\W/", "")
  org_id   = lower(local.org_name)
}

resource "harness_platform_organization" "this" {
  identifier  = local.org_id
  name        = local.org_name
  description = "A templated organization"
  tags = [
    "requestor:${var.requestor}",
    "source:github.com/rssnyder/harness-templates/HaC"
  ]

  // vm runs should be case-insensitive
  // dont change name if ran later with different case
  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

resource "harness_platform_project" "default" {
  identifier = "default"
  name       = "default"
  org_id     = harness_platform_organization.this.id
}

resource "harness_platform_usergroup" "approvers" {
  identifier = "approvers"
  name       = "approvers"
  org_id     = harness_platform_organization.this.id
  project_id = harness_platform_project.default.id
  users      = var.approvers
  notification_configs {
    type        = "EMAIL"
    group_email = "riley.snyder@harness.io"
  }
}

resource "harness_platform_environment" "dev" {
  identifier = "dev"
  name       = "dev"
  org_id     = harness_platform_organization.this.id
  project_id = harness_platform_project.default.id
  type       = "PreProduction"
  yaml       = <<EOF
environment:
  name: dev
  identifier: dev
  description: ""
  tags: {}
  type: PreProduction
  orgIdentifier: ${harness_platform_organization.this.id}
  projectIdentifier: ${harness_platform_project.default.id}
  variables: []
EOF
}

resource "harness_platform_infrastructure" "dev_k8s" {
  identifier      = "dev_k8s"
  name            = "dev_k8s"
  org_id          = harness_platform_organization.this.id
  project_id      = harness_platform_project.default.id
  env_id          = harness_platform_environment.dev.id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<EOF
infrastructureDefinition:
  name: dev_k8s
  identifier: dev_k8s
  description: ""
  tags: {}
  orgIdentifier: ${harness_platform_organization.this.id}
  projectIdentifier: ${harness_platform_project.default.id}
  environmentRef: ${harness_platform_environment.dev.id}
  deploymentType: Kubernetes
  type: KubernetesDirect
  spec:
    connectorRef: ${var.dev_k8s_connector}
    namespace: ${local.org_id}-${harness_platform_environment.dev.id}-<+service.name>
    releaseName: release-<+INFRA_KEY>
  allowSimultaneousDeployments: false
EOF
}

resource "harness_platform_environment" "staging" {
  identifier = "staging"
  name       = "staging"
  org_id     = harness_platform_organization.this.id
  project_id = harness_platform_project.default.id
  type       = "PreProduction"
  yaml       = <<EOF
environment:
  name: staging
  identifier: staging
  description: ""
  tags: {}
  type: PreProduction
  orgIdentifier: ${harness_platform_organization.this.id}
  projectIdentifier: ${harness_platform_project.default.id}
  variables: []
EOF
}

resource "harness_platform_infrastructure" "staging_k8s" {
  identifier      = "staging_k8s"
  name            = "staging_k8s"
  org_id          = harness_platform_organization.this.id
  project_id      = harness_platform_project.default.id
  env_id          = harness_platform_environment.staging.id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<EOF
infrastructureDefinition:
  name: staging_k8s
  identifier: staging_k8s
  description: ""
  tags: {}
  orgIdentifier: ${harness_platform_organization.this.id}
  projectIdentifier: ${harness_platform_project.default.id}
  environmentRef: ${harness_platform_environment.staging.id}
  deploymentType: Kubernetes
  type: KubernetesDirect
  spec:
    connectorRef: ${var.staging_k8s_connector}
    namespace: ${local.org_id}-${harness_platform_environment.staging.id}-<+service.name>
    releaseName: release-<+INFRA_KEY>
  allowSimultaneousDeployments: false
EOF
}

resource "harness_platform_environment" "production" {
  identifier = "production"
  name       = "production"
  org_id     = harness_platform_organization.this.id
  project_id = harness_platform_project.default.id
  type       = "Production"
  yaml       = <<EOF
environment:
  name: production
  identifier: production
  description: ""
  tags: {}
  type: Production
  orgIdentifier: ${harness_platform_organization.this.id}
  projectIdentifier: ${harness_platform_project.default.id}
  variables: []
EOF
}

resource "harness_platform_infrastructure" "production_k8s" {
  identifier      = "production_k8s"
  name            = "production_k8s"
  org_id          = harness_platform_organization.this.id
  project_id      = harness_platform_project.default.id
  env_id          = harness_platform_environment.production.id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<EOF
infrastructureDefinition:
  name: production_k8s
  identifier: production_k8s
  description: ""
  tags: {}
  orgIdentifier: ${harness_platform_organization.this.id}
  projectIdentifier: ${harness_platform_project.default.id}
  environmentRef: ${harness_platform_environment.production.id}
  deploymentType: Kubernetes
  type: KubernetesDirect
  spec:
    connectorRef: ${var.production_k8s_connector}
    namespace: ${local.org_id}-${harness_platform_environment.production.id}-<+service.name>
    releaseName: release-<+INFRA_KEY>
  allowSimultaneousDeployments: false
EOF
}

resource "harness_platform_pipeline" "build_image" {
  identifier  = "build_image"
  name        = "build_image"
  description = "this pipleine will be overriden by the yaml in the terraform"
  org_id      = harness_platform_organization.this.id
  project_id  = harness_platform_project.default.id

  yaml = <<EOF
pipeline:
  name: build_image
  identifier: build_image
  projectIdentifier: ${harness_platform_project.default.id}
  orgIdentifier: ${harness_platform_organization.this.id}
  tags: {}
  properties:
    ci:
      codebase:
        connectorRef: ${var.git_connector}
        repoName: <+input>
        build: <+input>
  stages:
    - stage:
        name: approve
        identifier: approve
        description: ""
        type: Approval
        tags: {}
        spec:
          execution:
            steps:
              - step:
                  name: approve
                  identifier: approve
                  type: HarnessApproval
                  timeout: 1d
                  spec:
                    approvalMessage: |-
                      Please review the following information
                      and approve the pipeline progression
                    includePipelineExecutionHistory: true
                    approvers:
                      minimumCount: 1
                      disallowPipelineExecutor: false
                      userGroups:
                        - ${harness_platform_usergroup.approvers.id}
                    approverInputs: []
    - stage:
        name: build
        identifier: build
        template:
          templateRef: account.build_imge
          versionLabel: "1"
          templateInputs:
            type: CI
            spec:
              execution:
                steps:
                  - step:
                      identifier: build_and_push
                      type: BuildAndPushDockerRegistry
                      spec:
                        dockerfile: <+input>
EOF
}

resource "harness_platform_pipeline" "build_image_git" {
  identifier  = "build_image_git"
  name        = "build_image_git"
  description = "this pipleine will sync to get, and terraform will never overrite it"
  org_id      = harness_platform_organization.this.id
  project_id  = harness_platform_project.default.id
  
  git_details {
    branch_name    = "master"
    commit_message = "creating pipeline"
    file_path      = ".example/tf_module_pipeline.yml"
    connector_ref  = "account.rssnyder"
    store_type     = "REMOTE"
    repo_name      = "test"
  }

  yaml = <<EOF
pipeline:
  name: build_image_git
  identifier: build_image_git
  projectIdentifier: ${harness_platform_project.default.id}
  orgIdentifier: ${harness_platform_organization.this.id}
  tags: {}
  properties:
    ci:
      codebase:
        connectorRef: ${var.git_connector}
        repoName: <+input>
        build: <+input>
  stages:
    - stage:
        name: approve
        identifier: approve
        description: ""
        type: Approval
        tags: {}
        spec:
          execution:
            steps:
              - step:
                  name: approve
                  identifier: approve
                  type: HarnessApproval
                  timeout: 1d
                  spec:
                    approvalMessage: |-
                      Please review the following information
                      and approve the pipeline progression
                    includePipelineExecutionHistory: true
                    approvers:
                      minimumCount: 1
                      disallowPipelineExecutor: false
                      userGroups:
                        - ${harness_platform_usergroup.approvers.id}
                    approverInputs: []
    - stage:
        name: build
        identifier: build
        template:
          templateRef: account.build_imge
          versionLabel: "1"
          templateInputs:
            type: CI
            spec:
              execution:
                steps:
                  - step:
                      identifier: build_and_push
                      type: BuildAndPushDockerRegistry
                      spec:
                        dockerfile: <+input>
EOF
  lifecycle {
    ignore_changes = [
      yaml,
    ]
  }
}
