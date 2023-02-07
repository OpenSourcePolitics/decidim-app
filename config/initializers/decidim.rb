# frozen_string_literal: true

Decidim.configure do |config|
  config.application_name = "OSP Agora"
  config.mailer_sender = "OSP Agora <ne-pas-repondre@opensourcepolitics.eu>"

  # Change these lines to set your preferred locales
  config.default_locale = ENV.fetch("DEFAULT_LOCALE", "en").to_sym
  config.available_locales = ENV.fetch("AVAILABLE_LOCALES", "en,fr").split(",").map(&:to_sym)

  # Timeout session
  config.expire_session_after = ENV.fetch("DECIDIM_SESSION_TIMEOUT", 180).to_i.minutes

  config.maximum_attachment_height_or_width = 6000

  # Rack Attack configs
  # Max requests in a time period to prevent DoS attacks. Only applied on production.
  config.throttling_max_requests = Rails.application.secrets.decidim[:throttling_max_requests].to_i

  # Time window in which the throttling is applied.
  config.throttling_period = Rails.application.secrets.decidim[:throttling_period].to_i.minutes

  # Whether SSL should be forced or not (only in production).
  config.force_ssl = (ENV.fetch("FORCE_SSL", "1") == "1") && Rails.env.production?

  # Geocoder configuration
  config.maps = {
    provider: :here,
    api_key: Rails.application.secrets.maps[:api_key],
    static: { url: "https://image.maps.ls.hereapi.com/mia/1.6/mapview" },
    autocomplete: {
      address_format: [%w(houseNumber street), "city", "country"]
    }
  }

  if defined?(Decidim::Initiatives) && defined?(Decidim::Initiatives.do_not_require_authorization)
    # puts "Decidim::Initiatives are loaded"
    Decidim::Initiatives.minimum_committee_members = 1
    Decidim::Initiatives.do_not_require_authorization = true
    Decidim::Initiatives.print_enabled = false
    Decidim::Initiatives.face_to_face_voting_allowed = false
  end

  # Custom resource reference generator method
  # config.resource_reference_generator = lambda do |resource, feature|
  #   # Implement your custom method to generate resources references
  #   "1234-#{resource.id}"
  # end

  # Currency unit
  config.currency_unit = Rails.application.secrets.decidim[:currency]

  # The number of reports which an object can receive before hiding it
  # config.max_reports_before_hiding = 3

  # Custom HTML Header snippets
  #
  # The most common use is to integrate third-party services that require some
  # extra JavaScript or CSS. Also, you can use it to add extra meta tags to the
  # HTML. Note that this will only be rendered in public pages, not in the admin
  # section.
  #
  # Before enabling this you should ensure that any tracking that might be done
  # is in accordance with the rules and regulations that apply to your
  # environment and usage scenarios. This feature also comes with the risk
  # that an organization's administrator injects malicious scripts to spy on or
  # take over user accounts.
  #
  config.enable_html_header_snippets = true

  # SMS gateway configuration
  #
  # If you want to verify your users by sending a verification code via
  # SMS you need to provide a SMS gateway service class.
  #
  # An example class would be something like:
  #
  # class MySMSGatewayService
  #   attr_reader :mobile_phone_number, :code
  #
  #   def initialize(mobile_phone_number, code)
  #     @mobile_phone_number = mobile_phone_number
  #     @code = code
  #   end
  #
  #   def deliver_code
  #     # Actual code to deliver the code
  #     true
  #   end
  # end
  #
  # config.sms_gateway_service = 'Decidim::Verifications::Sms::ExampleGateway'

  # Etherpad configuration
  #
  # Only needed if you want to have Etherpad integration with Decidim. See
  # Decidim docs at docs/services/etherpad.md in order to set it up.
  #

  if Rails.application.secrets.etherpad[:server].present?
    config.etherpad = {
      server: Rails.application.secrets.etherpad[:server],
      api_key: Rails.application.secrets.etherpad[:api_key],
      api_version: Rails.application.secrets.etherpad[:api_version]
    }
  end

  config.base_uploads_path = "#{ENV["HEROKU_APP_NAME"]}/" if ENV["HEROKU_APP_NAME"].present?
end

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

Rails.application.config.i18n.available_locales = Decidim.available_locales
Rails.application.config.i18n.default_locale = Decidim.default_locale

# Inform Decidim about the assets folder
Decidim.register_assets_path File.expand_path("app/packs", Rails.application.root)
