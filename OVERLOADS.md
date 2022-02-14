# Overrides

## Load decidim-awesome assets only if dependencie is present
* `app/views/layouts/decidim/_head.html.erb:33`

## Fix meetings orders in indexes
* `app/controllers/decidim/meetings/meetings_controller.rb`
* `app/controllers/decidim/meetings/directory/meetings_controller.rb`
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
 - **V0.24** `app/assets/stylesheets/decidim/vizzs/_areachart.scss`

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
