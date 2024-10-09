# Overrides 🍰
* `app/cells/decidim/version_cell.rb`
This override the default `VersionCell` from `decidim-core`, by adding sanitization for `version_number` to prevent XSS attacks.

* `app/controllers/decidim/assemblies/assemblies_controller.rb`
This override the default `AssembliesController` from `decidim-assemblies`, by adding custom sort for assembly_participatory_processes

* `app/helpers/decidim/assemblies/assemblies_helper.rb`
This override the default `AssembliesHelpler` from `decidim-assemblies`, by adding custom html for sorted assembly_participatory_processes

* `app/controllers/decidim/participatory_processes/participatory_processes_controller.rb`
This override the default `ParticipatoryProcessesController` from `decidim-participatory_processes`, by adding custom sort for participatory_processes

## Proposal's draft (Decidim awesome overrides 0.26.7)
* `app/views/decidim/proposals/collaborative_drafts/_edit_form_fields.html.erb`

## Deployment's related properties for API
* `app/api/deployment_type.rb`
* `app/api/query_extensions.rb`

## Rescue from ActiveStorage::InvariantError
* `lib/extends/uploaders/decidim/application_uploader_extends.rb`

## Fix cache on Hero Cell
* `lib/extends/cells/decidim/content_blocks/hero_cell_extends.rb:13`

## Add proposal map caching
* `app/views/decidim/proposals/proposals/index.html.erb:5`

## Update France Connect with requirements
* `app/views/decidim/devise/passwords/new.html.erb`
* `app/views/decidim/shared/_login_modal.html.erb`

## 28c8d74 - Add basic tests to reference package (#1), 2021-07-26
* `lib/extends/commands/decidim/admin/create_participatory_space_private_user_extends.rb`
* `lib/extends/commands/decidim/admin/impersonate_user_extends.rb`

## Fix metrics issue in admin dashboard
 - **app/packs/stylesheets/decidim/vizzs/_areachart.scss**
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

## Backups
* `app/helpers/decidim/backup_helper.rb`
83830be - Add retention service for daily backups (#19), 2021-11-09
* `app/services/decidim/s3_retention_service.rb`
de6d804 - fix multipart object tagging (#40) (#41), 2021-12-24
* `lib/tasks/restore_dump.rake`
705e0ad - Run rubocop, 2021-12-01

## Fix survey validation (#228)
* `app/cells/decidim/forms/step_navigation/show.erb`
* `app/packs/src/decidim/decidim_application.js`
* `app/views/decidim/forms/questionnaires/show.html.erb`
* `config/initializers/decidim_verifications.rb`
* `spec/shared/has_questionnaire.rb`
* `spec/system/survey_spec.rb`
