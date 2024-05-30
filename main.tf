terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.47.0"
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
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = templatefile(
      "${path.module}/cloud-init-master.yaml.tftpl",
      {
        hcloud_token = var.hcloud_token
        k3s_token    = var.k3s_token
      }
    )
  }
}

data "template_cloudinit_config" "worker_init" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = templatefile(
      "${path.module}/cloud-init-worker.yaml.tftpl",
      {
        k3s_token = var.k3s_token
      }
    )
  }
}

resource "hcloud_network" "kubernetes_network" {
  name     = "kubernetes-network"
  ip_range = "10.1.0.0/16"
  expose_routes_to_vswitch = false
  delete_protection = false
}

resource "hcloud_network_subnet" "kubernetes_network_subnet" {
  network_id   = hcloud_network.kubernetes_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.1.0.0/16"
}

resource "hcloud_firewall" "kubernetes_firewall" {
  name = "kubernetes-firewall"
  rule {
    description = "Allow SSH In"
    direction   = "in"
    protocol    = "tcp"
    port        = 22
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow ICMP In"
    direction   = "in"
    protocol    = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow HTTP In"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow HTTPS In"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow ICMP Out"
    direction = "out"
    protocol  = "icmp"
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow DNS TCP Out"
    direction = "out"
    protocol  = "tcp"
    port      = 53
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow DNS UDP Out"
    direction = "out"
    protocol  = "udp"
    port      = 53
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow HTTP Out"
    direction = "out"
    protocol  = "tcp"
    port      = 80
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow HTTPS Out"
    direction = "out"
    protocol  = "tcp"
    port      = 443
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow NTP UDP Out"
    direction = "out"
    protocol  = "udp"
    port      = 123
    destination_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_placement_group" "kubernetes_placement_group" {
  name = "kubernetes-placement-group"
  type = "spread"
}

resource "hcloud_server" "master_nodes" {
  count                      = var.master_count
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
  placement_group_id         = hcloud_placement_group.kubernetes_placement_group.id
  public_net {
    ipv4_enabled = var.enable_ipv4
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.kubernetes_network.id
  }
  user_data = data.template_cloudinit_config.master_init.rendered
  depends_on = [
    hcloud_network_subnet.kubernetes_network_subnet,
    hcloud_placement_group.kubernetes_placement_group
  ]
}

resource "hcloud_server" "worker_nodes" {
  count                      = var.worker_count
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
  placement_group_id         = hcloud_placement_group.kubernetes_placement_group.id
  public_net {
    ipv4_enabled = var.enable_ipv4
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.kubernetes_network.id
  }
  user_data = data.template_cloudinit_config.worker_init.rendered
  depends_on = [
    hcloud_network_subnet.kubernetes_network_subnet,
    hcloud_placement_group.kubernetes_placement_group,
    hcloud_server.master_nodes
  ]
}

resource "hcloud_firewall_attachment" "kubernetes_firewall_master_nodes" {
  count = var.master_count
  firewall_id = hcloud_firewall.kubernetes_firewall.id
  server_ids  = [
    hcloud_server.master_nodes[count.index].id
  ]
  depends_on = [
    hcloud_server.master_nodes
  ]
}

resource "hcloud_firewall_attachment" "kubernetes_firewall_worker_nodes" {
  count = var.worker_count
  firewall_id = hcloud_firewall.kubernetes_firewall.id
  server_ids  = [
    hcloud_server.worker_nodes[count.index].id
  ]
  depends_on = [
    hcloud_server.worker_nodes
  ]
}
