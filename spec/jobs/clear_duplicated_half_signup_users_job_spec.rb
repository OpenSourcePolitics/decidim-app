# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe ClearDuplicatedHalfSignupUsersJob do
    let!(:user1) { create(:user, phone_number: "1234567890", phone_country: "US", email: "user1@example.com") }
    let!(:user2) { create(:user, phone_number: "1234567890", phone_country: "US", email: "quick_auth_user@example.com") }
    let!(:user3) { create(:user, phone_number: "1234567890", phone_country: "US", email: "user3@example.com") }
    let!(:user4) { create(:user, phone_number: "9876543210", phone_country: "US", email: "user4@example.com") }

    before do
      allow_any_instance_of(Decidim::DestroyAccount).to receive(:call).and_return(true)
    end

    describe "#perform" do
      context "when no duplicated phone numbers are found" do
        it "prints that no duplicated phone numbers are found" do
          allow_any_instance_of(ClearDuplicatedHalfSignupUsersJob).to receive(:find_duplicated_phone_numbers).and_return([])

          expect { ClearDuplicatedHalfSignupUsersJob.perform_now }.to output(/No duplicated phone numbers found/).to_stdout
        end
      end

      context "when duplicated phone numbers are found" do
        before do
          user1
          user2
          user3
        end

        it "soft deletes quick_auth users" do
          expect_any_instance_of(ClearDuplicatedHalfSignupUsersJob).to receive(:soft_delete_user).with(user2, "Duplicated account")

          ClearDuplicatedHalfSignupUsersJob.perform_now
        end

        it "alerts about duplicated phone numbers for non-quick_auth users" do
          expect(Rails.logger).to receive(:warn).with(/ALERT: Duplicated Phone Number Detected/)

          ClearDuplicatedHalfSignupUsersJob.perform_now
        end

        it "does not soft delete non quick_auth users" do
          expect_any_instance_of(ClearDuplicatedHalfSignupUsersJob).not_to receive(:soft_delete_user).with(user1, "Duplicated account")

          ClearDuplicatedHalfSignupUsersJob.perform_now
        end

        it "does not soft delete users with different phone numbers" do
          expect_any_instance_of(ClearDuplicatedHalfSignupUsersJob).not_to receive(:soft_delete_user).with(user4, "Duplicated account")

          ClearDuplicatedHalfSignupUsersJob.perform_now
        end
      end
    end

    describe "#soft_delete_user" do
      let(:user) { create(:user, phone_number: "1234567890", phone_country: "US", email: "quick_auth_user@example.com") }

      it "updates the user to nullify the phone number and country" do
        expect(user).to receive(:update).with(phone_number: nil, phone_country: nil)

        subject.send(:soft_delete_user, user, "Duplicated account")
      end

      it "calls the Decidim::DestroyAccount service to delete the user" do
        allow_any_instance_of(Decidim::DestroyAccount).to receive(:call).and_return(true)

        subject.send(:soft_delete_user, user, "Duplicated account")
      end

      it "does not delete a non-quick_auth account" do
        user_with_diff_email = create(:user, phone_number: "1234567890", phone_country: "US", email: "user_diff@example.com")

        expect_any_instance_of(Decidim::DestroyAccount).not_to receive(:call)
        expect(Rails.logger).to receive(:info).with(/Not a Quick Auth account, skipping deletion/)

        subject.send(:soft_delete_user, user_with_diff_email, "Duplicated account")
      end
    end

    describe "#alert_about_duplicated_numbers" do
      let(:users) { [user1, user2, user3] }

      it "obfuscates the phone number and logs an alert message" do
        obfuscated_number = "12****90"
        allow(subject).to receive(:obfuscate_phone_number).with("1234567890").and_return(obfuscated_number)
        expect(Rails.logger).to receive(:warn).with(/ALERT: Duplicated Phone Number Detected/)

        subject.send(:alert_about_duplicated_numbers, "1234567890", users)
      end

      it "logs the correct message with the obfuscated phone number" do
        obfuscated_number = "12****90"
        allow(subject).to receive(:obfuscate_phone_number).with("1234567890").and_return(obfuscated_number)

        allow(Rails.logger).to receive(:warn) { |message|
          expect(message).to include("Phone Number: #{obfuscated_number}")
        }

        subject.send(:alert_about_duplicated_numbers, "1234567890", users)
      end
    end

    describe "#obfuscate_phone_number" do
      it "returns an obfuscated phone number with visible prefix and suffix" do
        result = subject.send(:obfuscate_phone_number, "1234567890")

        expect(result).to eq("12******90")
      end

      it 'returns "No phone number" if the phone number is blank' do
        result = subject.send(:obfuscate_phone_number, "")

        expect(result).to eq("No phone number")
      end

      it 'returns "No phone number" when given nil' do
        result = subject.send(:obfuscate_phone_number, nil)

        expect(result).to eq("No phone number")
      end
    end

    describe "#find_duplicated_phone_numbers" do
      context "when there are duplicates" do
        it "finds duplicated phone numbers" do
          user1
          user2
          user3

          result = subject.send(:find_duplicated_phone_numbers)

          expect(result).to include(%w(1234567890 US))
        end
      end
    end
  end
end
