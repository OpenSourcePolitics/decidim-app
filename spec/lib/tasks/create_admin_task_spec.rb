# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:create_admin", type: :task do
  let(:task_cmd) { :"decidim_app:create_admin" }
  let!(:organization) { create(:organization) }
  let(:name) { "John Doe" }
  let(:nickname) { "JD" }
  let(:email) { "john@example.org" }
  let(:password) { "decidim123456" }
  let(:organization_id) { organization.id.to_s }

  before do
    Rake::Task[task_cmd].reenable

    ENV["organization_id"] = organization_id
    ENV["name"] = name
    ENV["nickname"] = nickname
    ENV["email"] = email
    ENV["password"] = password
  end

  after do
    ENV["organization_id"] = ""
    ENV["name"] = ""
    ENV["nickname"] = ""
    ENV["email"] = ""
    ENV["password"] = ""
  end

  it "creates admin" do
    expect { Rake::Task[task_cmd].invoke }.to change(Decidim::User, :count).by(1)
    expect(Decidim::User.last.admin).to eq(true)
    expect(Decidim::User.last.nickname).to eq(nickname)
    expect(Decidim::User.last.organization).to eq(organization)
    expect(Decidim::User.last.email).to eq(email)
  end

  context "when organization is missing" do
    let(:organization_id) { nil }

    before do
      organization
    end

    it "creates admins with first organization" do
      expect { Rake::Task[task_cmd].invoke }.to change(Decidim::User, :count).by(1)
      expect(Decidim::User.last.admin).to eq(true)
      expect(Decidim::User.last.nickname).to eq(nickname)
      expect(Decidim::User.last.organization).to eq(organization)
      expect(Decidim::User.last.email).to eq(email)
    end
  end
end
