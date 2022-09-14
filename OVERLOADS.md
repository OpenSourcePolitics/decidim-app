# Overrides

## Load decidim-awesome assets only if dependencie is present
* `app/views/layouts/decidim/_head.html.erb:33`

## Fix geocoded proposals
* `app/controllers/decidim/proposals/proposals_controller.rb:44`
```ruby
          @all_geocoded_proposals = @base_query.geocoded.where.not(latitude: Float::NAN, longitude: Float::NAN)
```

##  Fix meetings registration serializer
* `app/serializers/decidim/meetings/registration_serializer.rb`
## Fix UserAnswersSerializer for CSV exports
* `lib/decidim/forms/user_answers_serializer.rb`
## 28c8d74 - Add basic tests to reference package (#1), 2021-07-26
* `lib/extends/commands/decidim/admin/create_participatory_space_private_user_extends.rb`
* `lib/extends/commands/decidim/admin/impersonate_user_extends.rb`
##  cd5c2cc - Backport fix/user answers serializer (#11), 2021-09-30
* `lib/decidim/forms/user_answers_serializer.rb`
## Fix metrics issue in admin dashboard
 - **app/stylesheets/decidim/vizzs/_areachart.scss**
```scss
    .area{
        fill: rgba($primary, .2);;
    }
```

## Add FC Connect SSO
 - **app/views/decidim/devise/shared/_omniauth_buttons.html.erb**
```ruby
    <% if provider.match?("france") %>
```

* `app/views/decidim/scopes/picker.html.erb`
c76437f - Modify cancel button behaviour to match close button, 2022-02-08

* `app/helpers/decidim/backup_helper.rb`
83830be - Add retention service for daily backups (#19), 2021-11-09

* `app/services/decidim/s3_retention_service.rb`
de6d804 - fix multipart object tagging (#40) (#41), 2021-12-24

* `config/initializers/omniauth_publik.rb`
9d50925 - Feature omniauth publik (#46), 2022-01-18

* `lib/tasks/restore_dump.rake`
705e0ad - Run rubocop, 2021-12-01
<<<<<<< HEAD
=======
## Disable proposals cells caching
- **app/cells/decidim/proposals/proposal_m_cell.rb:128**
* `app/queries/decidim/participatory_processes/organization_promoted_participatory_process_groups.rb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/models/decidim/proposals/proposal.rb`
f4536ea - Fix proposals permissions 0.24 (#64), 2022-03-11

* `app/packs/images/france-connect-logo.svg`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/images/FCboutons-10.png`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/images/FCboutons-10@2x.png`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/images/decidim/decidim-logo.svg`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/images/decidim/decidim-logo-mobile.svg`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/images/decidim/cc-by-sa--inv.svg`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/images/decidim/cc-by-sa.svg`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/images/decidim/decidim-logo-mobile--inv.svg`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/images/france-connect-logo-mono.svg`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/entrypoints/application.js`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/stylesheets/decidim/decidim_application.scss`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/stylesheets/decidim/_decidim-settings.scss`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/stylesheets/decidim/modules/_footer.scss`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/stylesheets/decidim/email/_email-custom.scss`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/stylesheets/decidim/vizzs/_areachart.scss`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/packs/src/decidim/decidim_application.js`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/commands/decidim/verifications/authorize_user.rb`
761d8fd - Fix/inter organizations messages (#77), 2022-03-23

* `app/commands/decidim/command.rb`
761d8fd - Fix/inter organizations messages (#77), 2022-03-23

* `app/events/decidim/verifications/managed_user_error_event.rb`
761d8fd - Fix/inter organizations messages (#77), 2022-03-23

* `app/controllers/decidim/participatory_processes/participatory_processes_controller.rb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/controllers/decidim/participatory_processes/participatory_process_groups_controller.rb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/controllers/decidim/verifications/authorizations_controller.rb`
761d8fd - Fix/inter organizations messages (#77), 2022-03-23

* `app/views/layouts/decidim/_main_footer.html.erb`
06cc6ca - Fix error with upload img footer, 2022-05-12

* `app/views/layouts/decidim/_mini_footer.html.erb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `app/views/layouts/decidim/_wrapper.html.erb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/assets.rb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/webpack/development.js`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/webpack/test.js`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/webpack/custom.js`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/webpack/base.js`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/webpack/production.js`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/webpacker.yml`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/initializers/decidim_questions.rb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/initializers/omniauth_france_connect.rb`
60a0355 - [Feature] - omniauth france connect library (#93), 2022-04-28

* `config/initializers/awesome_map.rb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

* `config/initializers/extends.rb`
151c45e - Extends Session controller and skip AH (#95), 2022-04-15

* `config/initializers/rack_attack.rb`
9722816 - Define asset host using ENV var + Enable rack attack throttle only on production mode (#72), 2022-03-18

* `lib/extends/queries/decidim/participatory_processes/group_participatory_processes_extends.rb`


* `lib/extends/controllers/decidim/devise/sessions_controller_extends.rb`
151c45e - Extends Session controller and skip AH (#95), 2022-04-15

* `lib/tasks/repare_data.rake`
5809fe6 - Add repare data rake task (#79), 2022-03-29

* `lib/tasks/migrate.rake`
d71197d - Add nil safety in migrate task, 2022-04-20

* `lib/decidim/test/promoted_participatory_processes_shared_examples.rb`
f12c07d - Bump Develop on 0.25 (#104), 2022-05-10

>>>>>>> develop
