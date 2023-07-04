# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:create_system_admin", type: :task do
  before do
    allow(Decidim::SystemAdminCreator).to receive(:create!).with(ENV).and_return(true)
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "invokes the admin creator" do
    task.execute

    # TODO: Investigate on flaky causing a double call on rake task when tested
    expect($stdout.string).to include("System admin created successfully\n")
  end
end
