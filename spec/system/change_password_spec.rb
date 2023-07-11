# frozen_string_literal: true

require "spec_helper"
require_relative "examples/change_password_examples"

describe "Registration", type: :system do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, password: "DfyvHn425mYAy2HL", organization: organization) }

  before do
    switch_to_host(organization.host)
    perform_enqueued_jobs { user.send_reset_password_instructions }
  end
  #TODO: reenable the test when friendly sign up is bumped
  #it_behaves_like "on/off change passwords"
end
