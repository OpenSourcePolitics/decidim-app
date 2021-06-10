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

  inbound_default_policy  = "accept"
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
}

resource "scaleway_instance_server" "decidim_app" {
  name = var.instance_name
  type  = var.instance_type
  image = var.instance_image

  tags = [ "decidim", "ansible" ]

  ip_id = scaleway_instance_ip.decidim_app_public_ip.id

  security_group_id = scaleway_instance_security_group.decidim_app_sg.id

  provisioner "remote-exec" {
  inline = ["sudo apt update -y", "sudo apt install python3 -y", "echo Done!"]

  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = var.user
    private_key = file(var.pvt_key)
    port        = var.sg_ssh_port
  }
}

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${self.public_ip}, -u ${var.user} -e 'ansible_port=${var.sg_ssh_port}' --private-key ${var.pvt_key} ../../ansible/playbooks/deploy_osp_app.yml"
  }
}