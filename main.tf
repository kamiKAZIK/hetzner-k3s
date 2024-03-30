terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.45.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

data "template_cloudinit_config" "master_init" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile(
      "cloud-init-master.yaml.tftpl",
      {
        public_worker_ssh_key = var.public_worker_ssh_key
      }
    )
  }
}

data "template_cloudinit_config" "worker_init" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile(
      "cloud-init-worker.yaml.tftpl",
      {
        private_worker_ssh_key = var.private_worker_ssh_key,
        public_worker_ssh_key = var.public_worker_ssh_key
      }
    )
  }
}

resource "hcloud_network" "kubernetes_network" {
  name     = "kubernetes-network"
  ip_range = "10.0.0.0/16"
  expose_routes_to_vswitch = false
  delete_protection = false
}

resource "hcloud_network_subnet" "kubernetes_network_subnet" {
  network_id   = hcloud_network.kubernetes_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
}

resource "hcloud_server" "master_nodes" {
  count                      = 1
  name                       = "master-node-${count.index}"
  image                      = "ubuntu-22.04"
  server_type                = "cax11"
  location                   = "fsn1"
  keep_disk                  = false
  shutdown_before_deletion   = false
  allow_deprecated_images    = false
  backups                    = false
  ignore_remote_firewall_ids = false
  rebuild_protection         = false
  delete_protection          = false
  ssh_keys                   = var.ssh_keys
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.kubernetes_network.id
  }
  user_data = data.template_cloudinit_config.master_init.rendered
  depends_on = [
    hcloud_network_subnet.kubernetes_network_subnet
  ]
}

resource "hcloud_server" "worker_nodes" {
  count                      = 0
  name                       = "worker-node-${count.index}"
  image                      = "ubuntu-22.04"
  server_type                = "cax11"
  location                   = "fsn1"
  keep_disk                  = false
  shutdown_before_deletion   = false
  allow_deprecated_images    = false
  backups                    = false
  ignore_remote_firewall_ids = false
  rebuild_protection         = false
  delete_protection          = false
  ssh_keys                   = var.ssh_keys
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.kubernetes_network.id
  }
  user_data = data.template_cloudinit_config.master_init.rendered
  depends_on = [
    hcloud_network_subnet.kubernetes_network_subnet,
    hcloud_server.master_nodes
  ]
}
