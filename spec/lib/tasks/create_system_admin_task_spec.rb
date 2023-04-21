# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:create_system_admin", type: :task do
  let(:task_cmd) { :"decidim_app:create_system_admin" }
  let(:email) { "john@example.org" }
  let(:password) { "decidim123456" }

  before do
    Rake::Task[task_cmd].reenable

    ENV["email"] = email
    ENV["password"] = password
  end

  after do
    ENV["email"] = ""
    ENV["password"] = ""
  end

  it "creates admin" do
    expect { Rake::Task[task_cmd].invoke }.to change(Decidim::System::Admin, :count).by(1)
    expect(Decidim::System::Admin.last.email).to eq(email)
  end
end
