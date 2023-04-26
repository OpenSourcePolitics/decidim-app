# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:create_admin", type: :task do
  let(:task_cmd) { :"decidim_app:create_admin" }
  let!(:organization) { create(:organization) }
  let(:name) { "John Doe 2" }
  let(:nickname) { "JD2" }
  let(:email) { "john2@example.org" }
  let(:password) { "decidim123456" }
  let(:organization_id) { organization.id.to_s }

  let(:environment) do
    {
      "organization_id" => organization_id,
      "name" => name,
      "nickname" => nickname,
      "email" => email,
      "password" => password
    }
  end

  it "creates admin" do
    with_modified_env(environment) do
      expect { Rake::Task[task_cmd].execute }.to change(Decidim::User, :count).by(1)
      expect(Decidim::User.last.admin).to eq(true)
      expect(Decidim::User.last.nickname).to eq(nickname)
      expect(Decidim::User.last.organization).to eq(organization)
      expect(Decidim::User.last.email).to eq(email)
    end
  end

  context "when organization is missing" do
    let(:organization_id) { nil }

    it "creates admins with first organization" do
      with_modified_env(environment) do
        expect { Rake::Task[task_cmd].execute }.to change(Decidim::User, :count).by(1)
        expect(Decidim::User.last.admin).to eq(true)
        expect(Decidim::User.last.nickname).to eq(nickname)
        expect(Decidim::User.last.organization).to eq(organization)
        expect(Decidim::User.last.email).to eq(email)
      end
    end
  end
end
