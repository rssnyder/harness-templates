# HaC - Harness as Code

A harness vending machine for pumping out organization from a pre-defined template.

Leverages a harness terraform pipeline to stamp out organizations based on a name given as runtime input. Uses the `backendConfig` feature of harness terraform pipelines to use an s3 state file based on the input so pipelines can be reran later to update existing organizations with any changes.

The pipeline yaml can be used as a base, pointing twards any terraform module that includes harness resources.
