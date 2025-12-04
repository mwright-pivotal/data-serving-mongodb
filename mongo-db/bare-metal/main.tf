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
  address = "https://192.168.0.89:4646"
  region  = "global"
  skip_verify = "true"
  secret_id = "super secret nomad secret id"
}
# Register a job
resource "nomad_job" "openvino-notebooks" {
  jobspec = file("${path.module}/mongodb-replicas.hcl")
}
