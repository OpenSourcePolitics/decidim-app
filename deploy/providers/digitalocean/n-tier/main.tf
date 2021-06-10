terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.8.0"
    }
  }
}

provider "digitalocean" {
}


resource "digitalocean_database_cluster" "decidim-app-pg" {
  name       = "decidim-app-pg"
  engine     = "pg"
  version    = "11"
  size       = var.cluster_size
  region     = var.region
  node_count = 1
}

resource "digitalocean_database_cluster" "decidim-app-redis" {
  name       = "decidim-app-redis"
  engine     = "redis"
  version    = "6"
  size       = var.cluster_size
  region     = var.region
  node_count = 1
}

resource "digitalocean_database_db" "decidim-app-db" {
  name       = "decidim-app-db"
  cluster_id = digitalocean_database_cluster.decidim-app-pg.id
}

resource "digitalocean_database_user" "decidim-user-pg" {
  name       = var.pg_user
  cluster_id = digitalocean_database_cluster.decidim-app-pg.id 
}

resource "digitalocean_spaces_bucket" "decidim-app-bucket" {
  name   = "decidim-app-assets"
  region = var.region
}

resource "digitalocean_vpc" "decidim-app-vpc" {
  name   = "decidim-app-vpc"
  region = var.region
}

resource "digitalocean_droplet" "decidim-app" {
  name     = "decidim-app"
  size     = var.droplet_size
  image    = var.image
  region   = var.region
  vpc_uuid = digitalocean_vpc.decidim-app-vpc.id
  ssh_keys = [var.ssh_key]
}

resource "digitalocean_database_firewall" "decidim-app-pg-fw" {
  cluster_id = digitalocean_database_cluster.decidim-app-pg.id

  rule {
    type  = "droplet"
    value = digitalocean_droplet.decidim-app.id
  }
}

resource "digitalocean_loadbalancer" "decidim-app-lb" {
  name     = "decidim-app-lb"
  region   = var.region
  vpc_uuid = digitalocean_vpc.decidim-app-vpc.id

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.decidim-app.id]
}

resource "digitalocean_project" "decidim-app-project" {
  name        = "decidim-app-project"
  description = "A project to represent development resources."
  environment = "Development"
  purpose     = "Decidim test application"
  resources   = [
                digitalocean_database_cluster.decidim-app-pg.urn,
                digitalocean_database_cluster.decidim-app-redis.urn,
                digitalocean_droplet.decidim-app.urn,
                digitalocean_loadbalancer.decidim-app-lb.urn,
                digitalocean_spaces_bucket.decidim-app-bucket.urn
                ]
}