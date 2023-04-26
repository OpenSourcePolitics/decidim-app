# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:create_system_admin", type: :task do
  let(:task_cmd) { :"decidim_app:create_system_admin" }
  let(:email) { "john@example.org" }
  let(:password) { "decidim123456" }

  let(:environment) do
    {
      "email" => email,
      "password" => password
    }
  end

  it "creates admin" do
    with_modified_env(environment) do
      expect { Rake::Task[task_cmd].execute }.to change(Decidim::System::Admin, :count).by(1)
      expect(Decidim::System::Admin.last.email).to eq(email)
    end
  end
end
