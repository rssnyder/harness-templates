locals {
  org_name = replace(replace(var.org, "/[ -]/", "_"), "/\\W/", "")
}

resource "harness_platform_organization" "this" {
  identifier  = lower(local.org_name)
  name        = local.org_name
  description = "A templated organization"
  tags = [
    "requestor:${var.requestor}",
    "source:github.com/rssnyder/harness-templates/HaC"
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

resource "harness_platform_input_set" "this" {
  identifier  = lower(local.org_name)
  name        = local.org_name
  org_id      = "default"
  project_id  = "Default_Project_1662659562703"
  pipeline_id = "vending_machine"
  yaml        = <<EOF
inputSet:
  identifier: ${lower(local.org_name)}
  name: ${local.org_name}
  orgIdentifier: "default"
  projectIdentifier: "Default_Project_1662659562703"
  pipeline:
    identifier: "vending_machine"
    variables:
    - name: "org_name"
      type: "String"
      value: "${var.org}"
EOF

  depends_on = [
    harness_platform_organization.this
  ]
}