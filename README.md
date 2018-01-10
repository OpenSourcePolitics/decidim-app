# OSP App

Citizen Participation and Open Government application.

This is a base app for all OSP projects. It uses OSP's decidim version.

## Deploying the app

* heroku run rake db:migrate
* Set SEED=1 as ENV variable
* heroku run rake db:seed --app osp-decidim
* See (Setting up the application .3)


## Setting up the application

You will need to do some steps before having the app working properly once you've deployed it:

1. Open a Rails console in the server: `bundle exec rails console`
2. Create a System Admin user:
```ruby
user = Decidim::System::Admin.new(email: <email>, password: <password>, password_confirmation: <password>)
user.save!
```
3. Visit `<your app url>/system` and login with your system admin credentials
4. Create a new organization. Check the locales you want to use for that organization, and select a default locale.
5. Set the correct default host for the organization, otherwise the app will not work properly. Note that you need to include any subdomain you might be using.
6. Fill the rest of the form and submit it.

You're good to go!

### How to deploy

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

1. Use the "Deploy to Heroku" button
1. Choose a name for the app, and organization and a tier
1. Fill in the required env vars.
1. Create the app
1. Enable Review Apps for this app (you'll need to create a Pipeline)
