# Overrides

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
