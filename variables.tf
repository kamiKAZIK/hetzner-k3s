variable "master_count" {
  default = 1
}

variable "worker_count" {
  default = 0
}

variable "enable_ipv4" {
  default = true
}

variable "hcloud_token" {
  sensitive = true
}

variable "ssh_keys" {
  sensitive = true
  type = list(string)
  default = []
  nullable = false
}

variable "k3s_token" {
  sensitive = true
}