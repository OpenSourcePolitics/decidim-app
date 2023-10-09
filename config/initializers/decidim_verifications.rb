# frozen_string_literal: true

if Rails.env.test?
  Decidim::Verifications.register_workflow(:another_dummy_authorization_handler) do |workflow|
    workflow.form = "AnotherDummyAuthorizationHandler"
    workflow.action_authorizer = "DummyAuthorizationHandler::DummyActionAuthorizer"
  end

  Decidim::Verifications.register_workflow(:dummy_authorization_handler) do |workflow|
    workflow.form = "DummyAuthorizationHandler"
    workflow.action_authorizer = "DummyAuthorizationHandler::DummyActionAuthorizer"
  end
else
  Decidim::Verifications.register_workflow(:osp_authorization_handler) do |auth|
    auth.form = "Decidim::OspAuthorizationHandler"
  end
end
