variable "hcloud_token" {
  sensitive = true
}

variable "public_worker_ssh_key" {
  sensitive = true
}

variable "private_worker_ssh_key" {
  sensitive = true
}

variable "ssh_keys" {
  type = list(string)
  default = []
  nullable = false
}
