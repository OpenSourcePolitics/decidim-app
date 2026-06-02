# frozen_string_literal: true

return unless Decidim.module_installed?(:initiatives)

Decidim::Initiatives.configure do |config|
  creation_enabled = Decidim::Env.new("INITIATIVES_CREATION_ENABLED", "auto").default_or_present_if_exists
  config.creation_enabled = creation_enabled.present? unless creation_enabled.to_s == "auto"

  config.minimum_committee_members = Decidim::Env.new("INITIATIVES_MINIMUM_COMMITTEE_MEMBERS", 2).to_i
  config.default_signature_time_period_length = Decidim::Env.new("INITIATIVES_DEFAULT_SIGNATURE_TIME_PERIOD_LENGTH", 120).to_i
  config.default_components = Decidim::Env.new("INITIATIVES_DEFAULT_COMPONENTS", "pages, meetings").to_array
  config.first_notification_percentage = Decidim::Env.new("INITIATIVES_FIRST_NOTIFICATION_PERCENTAGE", 33).to_i
  config.second_notification_percentage = Decidim::Env.new("INITIATIVES_SECOND_NOTIFICATION_PERCENTAGE", 66).to_i
  config.stats_cache_expiration_time = Decidim::Env.new("INITIATIVES_STATS_CACHE_EXPIRATION_TIME", 5).to_i.minutes
  config.max_time_in_validating_state = Decidim::Env.new("INITIATIVES_MAX_TIME_IN_VALIDATING_STATE", 60).to_i.days

  print_enabled = Decidim::Env.new("INITIATIVES_PRINT_ENABLED", "auto").default_or_present_if_exists
  config.print_enabled = print_enabled.present? unless print_enabled.to_s == "auto"

  config.do_not_require_authorization = Decidim::Env.new("INITIATIVES_DO_NOT_REQUIRE_AUTHORIZATION", false).to_boolean_string == "true"
end

# Signature workflows (introduced in Decidim 0.31, PR #13729).
# At least one workflow must be registered for initiative types to be
# configurable in the admin. The legacy handler reproduces the pre-0.31
# behaviour and must be available in all environments.
Decidim::Initiatives::Signatures.register_workflow(:legacy_signature_handler) do |workflow|
  workflow.form = "Decidim::Initiatives::LegacySignatureHandler"
  workflow.save_authorizations = false
  workflow.sms_verification = false
end

# Dummy workflows for local development and testing only.
# These classes are provided by decidim-dev and do not exist in production.
if Rails.env.development? || Rails.env.test?
  Decidim::Initiatives::Signatures.register_workflow(:dummy_signature_handler) do |workflow|
    workflow.form = "DummySignatureHandler"
    workflow.authorization_handler_form = "DummyAuthorizationHandler"
    workflow.action_authorizer = "DummySignatureHandler::DummySignatureActionAuthorizer"
    workflow.promote_authorization_validation_errors = true
    workflow.sms_verification = true
    workflow.sms_mobile_phone_validator = "DummySmsMobilePhoneValidator"
  end

  Decidim::Initiatives::Signatures.register_workflow(:ephemeral_dummy_signature_handler) do |workflow|
    workflow.form = "DummySignatureHandler"
    workflow.ephemeral = true
    workflow.authorization_handler_form = "DummyAuthorizationHandler"
    workflow.action_authorizer = "DummySignatureHandler::DummySignatureActionAuthorizer"
    workflow.promote_authorization_validation_errors = true
    workflow.sms_verification = true
    workflow.sms_mobile_phone_validator = "DummySmsMobilePhoneValidator"
  end

  Decidim::Initiatives::Signatures.register_workflow(:dummy_signature_with_sms_handler) do |workflow|
    workflow.sms_verification = true
  end

  Decidim::Initiatives::Signatures.register_workflow(:dummy_signature_with_personal_data_handler) do |workflow|
    workflow.form = "DummySignatureHandler"
    workflow.authorization_handler_form = "DummyAuthorizationHandler"
    workflow.action_authorizer = "DummySignatureHandler::DummySignatureActionAuthorizer"
    workflow.promote_authorization_validation_errors = true
  end
end
