# frozen_string_literal: true

require "spec_helper"

describe "rake decidim_app:budgets:send_sms_reminder", type: :task do
  let(:task) { Rake::Task["decidim_app:budgets:send_sms_reminder"] }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  context "when the budget does not exist" do
    it "prints Budget with id not found" do
      stub_const "ENV", ENV.to_h.merge("BUDGET_ID" => 0)
      expect { task.execute }.to output("\"Budget with id 0 not found\"\n").to_stdout
    end
  end

  context "when the budget exists" do
    let!(:budget) { create(:budget) }

    before do
      stub_const "ENV", ENV.to_h.merge("BUDGET_ID" => budget.id)
    end

    context "and there are no users with pending vote" do
      it "prints no pending votes" do
        expect { task.execute }.to output("\"no pending votes\"\n").to_stdout
      end
    end

    context "and there are users with pending votes but no phone number" do
      let!(:user) { create(:user, :confirmed, organization: budget.organization) }

      it "prints no pending votes from users with phone number" do
        Decidim::Budgets::Order.create!(decidim_user_id: user.id, decidim_budgets_budget_id: budget.id, checked_out_at: nil)
        expect { task.execute }.to output("\"no pending votes from users with phone number\"\n").to_stdout
      end
    end

    context "and there are users with pending votes and phone number" do
      let!(:user) { create(:user, :confirmed, organization: budget.organization, phone_number: "12345678", phone_country: "FR") }

      it "performs an http request" do
        # rubocop:disable RSpec/MessageChain
        allow(Rails).to receive_message_chain(:application, :secrets, :dig).with(:decidim, :sms_gateway, :bulk_url).and_return("https://sms.gateway.service/api/bulk")
        allow(Rails).to receive_message_chain(:application, :secrets, :dig).with(:decidim, :sms_gateway, :username).and_return("12345user")
        allow(Rails).to receive_message_chain(:application, :secrets, :dig).with(:decidim, :sms_gateway, :password).and_return("password12345")
        # rubocop:enable RSpec/MessageChain
        Decidim::Budgets::Order.create!(decidim_user_id: user.id, decidim_budgets_budget_id: budget.id, checked_out_at: nil)
        expect { task.execute }.to raise_error(WebMock::NetConnectNotAllowedError) # Real HTTP connections are disabled
      end
    end
  end
end
