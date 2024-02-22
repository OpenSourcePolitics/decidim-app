# Starting DecidimApp on Docker with HTTPS !

## Requirements
* **Docker** 
* **Docker-compose** 
* **Git**
* **Make**
* **OpenSSL**
* **PostgreSQL** 14+

## Installation

### Setup a clean Decidim App

1. Clone repository
2. Create a `.env` file from `.env.example` and fill it with your own values
3. Start the application with `make up`

Once containers are deployed, you should be able to visit : https://localhost:3000

Also, you should be automatically redirected to https://localhost:3000/system because your database is empty.

### Setup a seeded DecidimApp

1. Clone repository
2. Create a `.env` file from `.env-example` and fill it with your own values
3. Start the application with `make run`

Once containers are deployed, you should be able to visit : https://localhost:3000/ without being redirected !

## Informations

* Please use the `docker-compose.local.yml` in local environment because it uses `Dockerfile.local` which includes self signed certificate and allows to enable https in localhost
* If you want to cleanup your environmen run `make teardown` : it will stop containers and remove volumes and images

