# frozen_string_literal: true

Decidim.configure do |config|
  config.skip_first_login_authorization = ENV["SKIP_FIRST_LOGIN_AUTHORIZATION"] ? ActiveRecord::Type::Boolean.new.cast(ENV["SKIP_FIRST_LOGIN_AUTHORIZATION"]) : true
  config.application_name = "OSP Agora"
  config.mailer_sender = "OSP Agora <ne-pas-repondre@opensourcepolitics.eu>"

  # Change these lines to set your preferred locales
  config.default_locale = :en
  config.available_locales = [:en, :fr]

  config.maximum_attachment_height_or_width = 6000

  # Geocoder configuration
  if Rails.application.secrets.geocoder[:here_api_key].present?
    config.geocoder = {
      static_map_url: "https://image.maps.ls.hereapi.com/mia/1.6/mapview",
      here_api_key: Rails.application.secrets.geocoder[:here_api_key]
    }
  end

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
  # config.currency_unit = "€"

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

Rails.application.config.i18n.available_locales = Decidim.available_locales
Rails.application.config.i18n.default_locale = Decidim.default_locale
