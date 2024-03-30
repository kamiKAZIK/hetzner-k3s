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