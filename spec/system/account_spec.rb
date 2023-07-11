# frozen_string_literal: true

require "spec_helper"
require_relative "examples/account_password_examples"

describe "Registration", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization: organization) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  #TODO: reenable the test when friendly sign up is bumped
  #it_behaves_like "on/off account passwords"
end
