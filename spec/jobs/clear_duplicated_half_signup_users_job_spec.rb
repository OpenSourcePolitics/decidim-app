# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe ClearDuplicatedHalfSignupUsersJob do
    subject { described_class.perform_now }

    let(:logger) { Logger.new(StringIO.new) }

    let!(:user1) { create(:user, phone_number: "1234567890", phone_country: "US", email: "user1@example.com") }
    let!(:user2) { create(:user, phone_number: phonenumberuser2, phone_country: "US", email: "quick_auth_user@example.com") }
    let!(:user3) { create(:user, phone_number: phonenumberuser3, phone_country: "US", email: "user3@example.com") }
    let!(:user4) { create(:user, phone_number: "9876543210", phone_country: "US", email: "user4@example.com") }
    let(:delete_reason) { "HalfSignup duplicated account (#{current_date})" }
    let(:current_date) { Date.current.strftime "%Y-%m-%d" }

    let(:phonenumberuser2) { "1234567890" }
    let(:phonenumberuser3) { "1234567890" }

    before do
      allow_any_instance_of(Decidim::Logging).to receive(:stdout_logger).and_return(logger)
      allow_any_instance_of(Decidim::DestroyAccount).to receive(:call).and_return(true)
    end

    describe "#perform" do
      context "when no duplicated phone numbers are found" do
        let(:phonenumberuser2) { "1234567891" }
        let(:phonenumberuser3) { "1234567892" }

        it "prints that no duplicated phone numbers are found" do
          expect { subject }.to output(/No duplicated phone numbers found/).to_stdout
          puts "ok"
        end
      end

      context "when duplicated phone numbers are found" do
        before do
          allow_any_instance_of(ClearDuplicatedHalfSignupUsersJob).to receive(:duplicated_phone_numbers).and_return([%w(1234567890 US)])
        end

        it "soft deletes quick_auth users" do
          expect_any_instance_of(ClearDuplicatedHalfSignupUsersJob).to receive(:soft_delete_user).with(user2, delete_reason)

          subject
        end

        it "alerts about duplicated phone numbers for non-quick_auth users" do
          expect(Rails.logger).to receive(:warn).and_call_original
          expect(Rails.logger).to receive(:warn).with(/ALERT: Duplicated Phone Number Detected/)

          subject
        end

        it "does not soft delete non quick_auth users" do
          expect_any_instance_of(ClearDuplicatedHalfSignupUsersJob).not_to receive(:soft_delete_user).with(user1, delete_reason)

          subject
        end

        it "does not soft delete users with different phone numbers" do
          expect_any_instance_of(ClearDuplicatedHalfSignupUsersJob).not_to receive(:soft_delete_user).with(user4, delete_reason)

          subject
        end
      end
    end

    describe "#soft_delete_user" do
      let(:user) { create(:user, phone_number: "1234567890", phone_country: "US", email: "quick_auth_user@example.com") }

      it "updates the user to nullify the phone number and country" do
        expect(user).to receive(:update).with(phone_number: nil, phone_country: nil)

        described_class.new.send(:soft_delete_user, user, delete_reason)
      end

      it "calls the Decidim::DestroyAccount service to delete the user" do
        expect_any_instance_of(Decidim::DestroyAccount).to receive(:call)

        described_class.new.send(:soft_delete_user, user, delete_reason)
      end

      it "does not delete a non-quick_auth account" do
        user_with_diff_email = create(:user, phone_number: "1234567890", phone_country: "US", email: "user_diff@example.com")

        expect_any_instance_of(Decidim::DestroyAccount).not_to receive(:call)
        expect(Rails.logger).to receive(:info).with(/Not a Quick Auth account, skipping deletion/)

        described_class.new.send(:soft_delete_user, user_with_diff_email, delete_reason)
      end
    end

    describe "#alert_about_duplicated_numbers" do
      let(:users) { [user1, user2, user3] }

      it "obfuscates the phone number and logs an alert message" do
        allow_any_instance_of(ClearDuplicatedHalfSignupUsersJob).to receive(:obfuscate_phone_number).with("1234567890").and_return("12****90")

        described_class.new.send(:generate_alert_message, "1234567890", users)
      end
    end

    describe "#obfuscate_phone_number" do
      it "returns an obfuscated phone number with visible prefix and suffix" do
        result = described_class.new.send(:obfuscate_phone_number, "1234567890")

        expect(result).to eq("12******90")
      end

      it 'returns "No phone number" if the phone number is blank' do
        result = described_class.new.send(:obfuscate_phone_number, "")

        expect(result).to eq("No phone number")
      end

      it 'returns "No phone number" when given nil' do
        result = described_class.new.send(:obfuscate_phone_number, nil)

        expect(result).to eq("No phone number")
      end
    end

    describe "#duplicated_phone_numbers" do
      it "finds duplicated phone numbers" do
        result = described_class.new.send(:duplicated_phone_numbers)

        expect(result).to include(%w(1234567890 US))
      end
    end
  end
end
