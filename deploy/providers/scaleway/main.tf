terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  zone            = "fr-par-1"
  region          = "fr-par"
}

resource "scaleway_instance_ip" "decidim_app_public_ip" {}

resource "scaleway_instance_security_group" "decidim_app_sg" {

  name = var.sg_name

  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  
  enable_default_security = "false"

  inbound_rule {
    action = "accept"
    port   = var.sg_ssh_port
  }

  inbound_rule {
    action = "accept"
    port   = "80"
  }

  inbound_rule {
    action = "accept"
    port   = "443"
  }
}

resource "scaleway_instance_server" "decidim_app" {
  name = var.instance_name
  type  = var.instance_type
  image = var.instance_image

  tags = [ "decidim", "deploy_decidim" ]

  ip_id = scaleway_instance_ip.decidim_app_public_ip.id

  security_group_id = scaleway_instance_security_group.decidim_app_sg.id
}