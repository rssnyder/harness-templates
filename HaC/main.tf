resource "harness_platform_organization" "this" {
  identifier  = lower(var.org)
  name        = var.org
  description = "A templated organization"
  tags = [
    "source:git",
    "git:rssnyder/harness-templates/HaC"
  ]
}
