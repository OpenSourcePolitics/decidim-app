# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:create_admin", type: :task do
  let(:task_cmd) { "decidim_app:create_admin" }

  before do
    allow(Decidim::AdminCreator).to receive(:create!).with(ENV).and_return(true)

    Rake::Task[task_cmd].reenable
  end

  it "invokes the admin creator" do
    expect { Rake::Task[task_cmd].invoke }.to output("Admin created successfully\n").to_stdout
  end
end
