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

## Fix collaborative draft
* `app/controllers/decidim/proposals/collaborative_drafts_controller.rb`
* `app/views/decidim/proposals/collaborative_drafts/_wizard_aside.html.erb`
* `app/views/v0.26/decidim/proposals/collaborative_drafts/_show.html.erb`
* `spec/system/collaborative_drafts_fields_spec.rb`

## Add budget reminder(#170)
* `app/commands/decidim/budgets/admin/create_order_reminders.rb`
* `app/controllers/decidim/admin/components/base_controller.rb`
* `app/controllers/decidim/admin/reminders_controller.rb`
* `app/controllers/decidim/assemblies/admin/reminders_controller.rb`
* `app/controllers/decidim/conferences/admin/reminders_controller.rb`
* `app/controllers/decidim/participatory_processes/admin/reminders_controller.rb`
* `app/forms/decidim/budgets/admin/order_reminder_form.rb`
* `app/helpers/decidim/admin/reminders_helper.rb`
* `app/jobs/decidim/budgets/send_vote_reminder_job.rb`
* `app/jobs/decidim/reminder_generator_job.rb`
* `app/mailers/decidim/budgets/vote_reminder_mailer.rb`
* `app/models/decidim/reminder.rb`
* `app/models/decidim/reminder_delivery.rb`
* `app/models/decidim/reminder_record.rb`
* `app/models/decidim/user.rb`
* `app/permissions/decidim/admin/permissions.rb`
* `app/permissions/decidim/budgets/admin/permissions.rb`
* `app/services/decidim/budgets/order_reminder_generator.rb`
* `app/views/decidim/admin/reminders/new.html.erb`
* `app/views/decidim/budgets/admin/budgets/index.html.erb`
* `app/views/decidim/budgets/vote_reminder_mailer/vote_reminder.html.erb`
* `config/i18n-tasks.yml`
```ruby
  - decidim.budgets.admin.reminders.orders.*
```
* `config/initializers/decidim.rb`
```ruby
Decidim.module_eval do
  autoload :ReminderRegistry, "decidim/reminder_registry"
  autoload :ReminderManifest, "decidim/reminder_manifest"
  autoload :ManifestMessages, "decidim/manifest_messages"

  def self.reminders_registry
    @reminders_registry ||= Decidim::ReminderRegistry.new
  end
end

Decidim.reminders_registry.register(:orders) do |reminder_registry|
  reminder_registry.generator_class_name = "Decidim::Budgets::OrderReminderGenerator"
  reminder_registry.form_class_name = "Decidim::Budgets::Admin::OrderReminderForm"
  reminder_registry.command_class_name = "Decidim::Budgets::Admin::CreateOrderReminders"

  reminder_registry.settings do |settings|
    settings.attribute :reminder_times, type: :array, default: [2.hours, 1.week, 2.weeks]
  end

  reminder_registry.messages do |msg|
    msg.set(:title) { |count: 0| I18n.t("decidim.budgets.admin.reminders.orders.title", count: count) }
    msg.set(:description) { I18n.t("decidim.budgets.admin.reminders.orders.description") }
  end
end
```
* `config/locales/en.yaml`
* `config/locales/fr.yaml`
* `config/routes.rb`
```ruby
Decidim::Assemblies::AdminEngine.class_eval do
  routes do
    scope "/assemblies/:assembly_slug" do
      resources :components do
        resources :reminders, only: [:new, :create]
      end
    end
  end
end

Decidim::Conferences::AdminEngine.class_eval do
  routes do
    scope "/conferences/:conference_slug" do
      resources :components do
        resources :reminders, only: [:new, :create]
      end
    end
  end
end

Decidim::ParticipatoryProcesses::AdminEngine.class_eval do
  routes do
    scope "/participatory_processes/:participatory_process_slug" do
      resources :components do
        resources :reminders, only: [:new, :create]
      end
    end
  end
end
```
* `db/migrate/20211208155453_create_decidim_reminders.rb`
* `db/migrate/20211209121025_create_decidim_reminder_records.rb`
* `db/migrate/20211209121040_create_decidim_reminder_deliveries.rb`
* `lib/decidim/core/test/factories.rb`
* `lib/decidim/importers/import_manifest.rb`
* `lib/decidim/manifest_messages.rb`
* `lib/decidim/reminder_manifest.rb`
* `lib/decidim/reminder_registry.rb`
* `lib/tasks/decidim_reminders_tasks.rake`
* `spec/commands/decidim/budgets/admin/create_order_reminders_spec.rb`
* `spec/forms/decidim/budgets/admin/order_reminder_form_spec.rb`
* `spec/jobs/decidim/budgets/send_vote_reminder_job_spec.rb`
* `spec/jobs/decidim/reminder_generator_job_spec.rb`
* `spec/lib/importers/import_manifest_spec.rb`
* `spec/lib/reminder_registry_spec.rb`
* `spec/mailers/decidim/budgets/vote_reminder_mailer_spec.rb`
* `spec/services/decidim/budgets/order_reminder_generator_spec.rb`
* `spec/system/admin_reminds_users_with_pending_orders_spec.rb`
