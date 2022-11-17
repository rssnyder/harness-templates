resource "harness_organization" "this" {
  identifier  = var.org
  name        = var.org
  description = "A templated organization"
  tags = [
    "source:git",
    "git:rssnyder/harness-templates/HaC"
  ]
}
