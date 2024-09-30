# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Initiative do
    subject { initiative }

    let(:organization) { create(:organization) }

    context "when validating an initiative" do
      context "and description contains an img tag" do
        let(:validating_initiative) do
          build(:initiative,
                description: { en: 'description<img src="invalid.jpg" onerror="alert();">' },
                state: "validating")
        end

        it "is not valid" do
          expect(validating_initiative).not_to be_valid
        end
      end

      context "and description is valid" do
        let(:validating_initiative) do
          build(:initiative,
                description: { en: "description" },
                state: "validating")
        end

        it "is valid" do
          expect(validating_initiative).to be_valid
        end
      end
    end
  end
end
