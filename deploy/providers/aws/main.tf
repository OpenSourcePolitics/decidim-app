provider "aws" {}

resource "aws_instance" "decidim_app" {
  ami = "ami-0d6aecf0f0425f42a" # eu-west-3
  instance_type = var.instance_type
  associate_public_ip_address = "true"
  key_name = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
}
