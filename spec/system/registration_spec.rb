# frozen_string_literal: true

require "spec_helper"
require_relative "examples/registration_password_examples"
require_relative "examples/registration_instant_validation_examples"
require_relative "examples/registration_hide_nickname_examples"

describe "Registration", type: :system do
  let(:organization) { create(:organization) }

  before do
    switch_to_host(organization.host)
  end

  it_behaves_like "on/off registration passwords"

  it_behaves_like "on/off registration instant validation"

  it_behaves_like "on/off registration hide nickname"
end
