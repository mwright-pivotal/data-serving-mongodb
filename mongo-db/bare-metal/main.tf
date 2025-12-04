# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


terraform {
  required_providers {
    nomad = {
      source = "hashicorp/nomad"
      version = "2.3.0"
    }
  }
  cloud { 
    organization = "mwright_org" 
  } 
}

provider "nomad" {
  address = var.nomad_addr
  secret_id = var.nomad_token
}
# Register a job
resource "nomad_job" "mongodb-bare-metal-lpar" {
  jobspec = file("${path.module}/mongodb-replicas.hcl")
}
