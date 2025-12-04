variable "nomad_token" {
    description = "Nomad authentication token"
    type        = string
    sensitive   = true
}

variable "nomad_addr" {
    description = "Nomad server address"
    type        = string
}