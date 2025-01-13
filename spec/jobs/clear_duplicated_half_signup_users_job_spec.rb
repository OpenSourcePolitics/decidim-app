# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe ClearDuplicatedHalfSignupUsersJob do
    subject { described_class.perform_now }

    let!(:dup_user1) { create(:user, phone_number: "1234", phone_country: "US", email: "user1@example.com") }
    let!(:dup_user2) { create(:user, phone_number: "1234", phone_country: "US", email: "quick_auth_user@example.com") }
    let!(:dup_user3) { create(:user, phone_number: "1234", phone_country: "US", email: "user3@example.com") }
    let(:dup_user4) do
      dup_user4 = build(:user, phone_number: "1234", phone_country: "US", email: "")
      dup_user4.save(validate: false)
      dup_user4
    end
    let!(:user5) { create(:user, phone_number: "6789", phone_country: "US", email: "user5@example.com") }
    let(:delete_reason) { "HalfSignup duplicated account (#{current_date})" }
    let(:current_date) { Date.current.strftime "%Y-%m-%d" }

    before do
      allow(Decidim::Logging).to receive(:stdout_logger).and_return(Logger.new(StringIO.new))
    end

    describe "#perform" do
      it "soft deletes quick_auth users" do
        expect_any_instance_of(ClearDuplicatedHalfSignupUsersJob).to receive(:soft_delete_user).with(dup_user2, delete_reason)

        subject
      end

      it "does not soft delete non quick_auth users" do
        expect_any_instance_of(ClearDuplicatedHalfSignupUsersJob).not_to receive(:soft_delete_user).with(dup_user1, delete_reason)

        subject
      end
    end

    describe "#clear_data" do
      let(:object) do
        obj = described_class.new
        obj.instance_variable_set(:@dup_half_signup_count, 0)
        obj.instance_variable_set(:@dup_decidim_users_count, 0)
        obj
      end

      it "clears the phone number and country of the users" do
        expect(dup_user1.phone_number).to eq("1234")
        expect(dup_user1.phone_country).to eq("US")
        object.send(:clear_data, [dup_user1, dup_user3])
        dup_user1.reload

        expect(dup_user1.phone_number).to be_nil
        expect(dup_user1.phone_country).to be_nil
        expect(dup_user1.extended_data).to include("half_signup" => {
                                                     "phone_number" => "1234",
                                                     "phone_country" => "US"
                                                   })
        expect(object.instance_variable_get(:@dup_half_signup_count)).to eq(0)
        expect(object.instance_variable_get(:@dup_decidim_users_count)).to eq(2)
      end

      context "when user is not half signup and email is empty" do
        it "does clear the phone number and country of the user" do
          expect(dup_user4.phone_number).to eq("1234")
          expect(dup_user4.phone_country).to eq("US")
          object.send(:clear_data, [dup_user4])
          dup_user4.reload

          expect(dup_user4.phone_number).to be_nil
          expect(dup_user4.phone_country).to be_nil
          expect(dup_user4.extended_data).to include("half_signup" => {
                                                       "phone_number" => "1234",
                                                       "phone_country" => "US"
                                                     })
          expect(object.instance_variable_get(:@dup_half_signup_count)).to eq(0)
          expect(object.instance_variable_get(:@dup_decidim_users_count)).to eq(1)
        end
      end
    end

    describe "#soft_delete_user" do
      it "updates the user to nullify the phone number and country" do
        expect(dup_user2.phone_number).to eq("1234")
        expect(dup_user2.phone_country).to eq("US")
        described_class.new.send(:soft_delete_user, dup_user2, delete_reason)
        dup_user2.reload

        expect(dup_user2.phone_number).to be_nil
        expect(dup_user2.phone_country).to be_nil
        expect(dup_user2.extended_data).to include("half_signup" => {
                                                     "email" => "quick_auth_user@example.com",
                                                     "phone_number" => "1234",
                                                     "phone_country" => "US"
                                                   })
      end

      it "calls the Decidim::DestroyAccount service to delete the half signup user" do
        expect_any_instance_of(Decidim::DestroyAccount).to receive(:call)

        described_class.new.send(:soft_delete_user, dup_user2, delete_reason)
      end

      it "does not delete a non-quick_auth account" do
        user_with_diff_email = create(:user, phone_number: "1234", phone_country: "US", email: "user_diff@example.com")

        expect_any_instance_of(Decidim::DestroyAccount).not_to receive(:call)

        described_class.new.send(:soft_delete_user, user_with_diff_email, delete_reason)
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

        expect(result).to include(%w(1234 US))
      end
    end
  end
end
