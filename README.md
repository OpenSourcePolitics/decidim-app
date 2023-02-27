# Decidim app by OSP

Citizen Participation and Open Government application based on [Decidim](https://github.com/decidim/decidim).

This application is maintained by [Open Source Politics](https://opensourcepolitics.eu/). Some non official customizations can be found see [OVERLOADS.MD](./OVERLOADS.md).

[![codecov](https://codecov.io/gh/OpenSourcePolitics/decidim-app/branch/master/graph/badge.svg?token=VDQ3ORQLN6)](https://codecov.io/gh/OpenSourcePolitics/decidim-app)
[![Maintainability](https://api.codeclimate.com/v1/badges/f5abcda931760d6ee65d/maintainability)](https://codeclimate.com/github/OpenSourcePolitics/decidim-app/maintainability)
![Tests](https://github.com/OpenSourcePolitics/decidim-app/actions/workflows/deploy_production.yml/badge.svg?branch=master)
![Tests](https://github.com/OpenSourcePolitics/decidim-app/actions/workflows/tests.yml/badge.svg?branch=master)


## Installation guide

Once repository is cloned, you can now install dependencies, fetch external migrations and migrate

> We created a rake task to install automatically the dependencies

Execute command : 
> bundle exec rake decidim_app:setup

Otherwise follow these steps : 

1. Install dependencies

```bash
bundle install
```
2. Install Decidim Awesome dependencies
```bash
bundle exec rails decidim_decidim_awesome:install:migrations
bundle exec rails decidim_decidim_awesome:webpacker:install
```
3. Install Homepage Interactive Map dependencies
```bash
bundle exec rake decidim_homepage_interactive_map:install:migrations
```
4. Install Term Customizer dependencies
```bash
bundle exec rails decidim_term_customizer:install:migrations
```

5. Install Ludens dependencies and initialize the module
```bash
bundle exec rake decidim_ludens:install:migrations
bundle exec rake decidim_ludens:initialize
```
6. Install migrations

```bash
bundle exec rake db:migrate
```

All dependencies should be now installed and ready-to-use !

## Setting up the application

You will need to do some steps before having the app working properly once you've deployed it:

1. Open a Rails console in the server: `bundle exec rails console`
2. Create a System Admin user:
```ruby
email = <your email>
password = <a secure password>
user = Decidim::System::Admin.new(email: email, password: password, password_confirmation: password)
user.save!
```
3. Visit `<your app url>/system` and login with your system admin credentials
4. Create a new organization. Check the locales you want to use for that organization, and select a default locale.
5. Set the correct default host for the organization, otherwise the app will not work properly. Note that you need to include any subdomain you might be using.
6. Fill the rest of the form and submit it.

__IMPORTANT!__ : You must ensure all environnement variables are defined, see [.env-example](./.env-example)

You're good to go!

## Running tests

This application has a functional testing suite. You can easily run locally the tests as following :

Create test environment database 

`bundle exec rake test:setup`

And then run tests using `rspec`

`bundle exec rspec spec/`

## Docker
### How to use it? 
You can boot a Decidim environment in Docker using the Makefile taht will run docker-compose commands and the last built image from the Dockerfile.
Three context are available : 

- **Clean Decidim**

An environment running the current Decidim version (from Gemfile) without any data.
```make
make start-clean-decidim
```

- **Seeded Decidim**

An environment running the current Decidim version (from Gemfile) with generated seeds
```make
make start-seeded-decidim
```

- **Dumped Decidim**

An environment running the current Decidim version (from Gemfile) with real data dumped from an existing platform to simulate a Decidim bump version before doing in the real production environment.
```make
make start-dumped-decidim
```
***Warning : you need to get a psql dump on your local machine to restore it in your containerized database***
***Warning2 : you need to set organization host to 0.0.0.0 with the rails console***


### How to stop and remove it? 

To get rid off your Docker environmnent : 

- Shut down Docker environmnent
```make
make stop
```

- Delete resources
```make
make delete
```
### Troubleshooting

Make commands are available to help you troubleshoot your Docker environment

- Start Rails console
 ```make
make rails-console
```
- Start bash session to app container
```make
make connect-app
```

## Deploy with Terraform

Terraform is an open-source infrastructure as code software tool that provides an easy deployment of your infrastructure for installing Decidim.

Many providers are available (**AWS**, **Heroku**, **DigitalOcean**...). Check the [Terraform registry to see how to use Terraform with your provider](https://registry.terraform.io/browse/providers)

Each Terraform deployment are stored in the **deploy** folder and sorted by providers

Feel free to add new deployments!

## Availables deployments

- [Scaleway](https://github.com/OpenSourcePolitics/decidim-app/tree/develop/deploy/providers/scaleway)
- [DigitalOcean](https://github.com/OpenSourcePolitics/decidim-app/tree/develop/deploy/providers/digitalocean/)

## Environment variables

Each provider will need a way to authenticate at their API. Make sure to set environment variables asked in the provider's documentation before using deployments.

- To use Scaleway's provider

```bash
export SCW_ACCESS_KEY=<your_access_key>
export SCW_TOKEN=<your_scw_token>
export SCW_DEFAULT_PROJECT_ID=<id_of_your_project/organization>
```

- To use DigitalOcean's provider
```bash
export DIGITALOCEAN_TOKEN=<your_do_token>
export SPACES_ACCESS_KEY_ID=<your_do_space_access_key>
export SPACES_SECRET_ACCESS_KEY=<your_do_space_secret_key>
```

## How to deploy with Terraform?

Check the list of make commands in the Makefile. Each command corresponds to a provider and a specific need.

- To deploy a new infrastructure with Scaleway

```make
make deploy-scw
```

## Database architecture (ERD)

![Architecture_decidim](https://user-images.githubusercontent.com/52420208/133789299-9458fc42-a5e7-4e3d-a934-b55c6afbc8aa.jpg)
