resource "harness_platform_organization" "this" {
  identifier  = lower(var.org)
  name        = var.org
  description = "A templated organization"
  tags = [
    "source:git",
    "git:rssnyder/harness-templates/HaC"
  ]
}

resource "harness_platform_project" "default" {
  identifier = "default"
  name       = "default"
  org_id     = harness_platform_organization.this.id
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
  orgIdentifier: default
  projectIdentifier: default
  variables: []
EOF
}

resource "harness_platform_infrastructure" "dev_sa" {
  identifier      = "sa"
  name            = "sa"
  org_id          = harness_platform_organization.this.id
  project_id      = harness_platform_project.default.id
  env_id          = harness_platform_environment.dev.id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<EOF
infrastructureDefinition:
  name: sa
  identifier: sa
  description: ""
  tags: {}
  orgIdentifier: default
  projectIdentifier: default
  environmentRef: dev
  deploymentType: Kubernetes
  type: KubernetesDirect
  spec:
    connectorRef: account.sagcp
    namespace: riley-dev-<+service.name>
    releaseName: release-<+INFRA_KEY>
  allowSimultaneousDeployments: false
EOF
}