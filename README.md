# Decidim app by OSP

Citizen Participation and Open Government application.

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

You're good to go!

