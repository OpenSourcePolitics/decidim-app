# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe InitiativeForm do
      subject { described_class.from_params(attributes).with_context(context) }

      let(:organization) { create(:organization) }
      let(:initiatives_type) { create(:initiatives_type, organization: organization) }
      let(:scope) { create(:initiatives_type_scope, type: initiatives_type) }
      let(:attachment_params) { nil }

      let(:title) { ::Faker::Lorem.sentence(word_count: 5) }
      let(:my_description) { "" }
      let(:attributes) do
        {
          title: title,
          description: my_description,
          type_id: initiatives_type.id,
          scope_id: scope&.scope&.id,
          signature_type: "offline",
          attachment: attachment_params
        }.merge(custom_signature_end_date).merge(area)
      end
      let(:custom_signature_end_date) { {} }
      let(:area) { {} }
      let(:context) do
        {
          current_organization: organization,
          current_component: nil,
          initiative_type: initiatives_type
        }
      end
      let(:state) { "validating" }
      let(:initiative) { create(:initiative, organization: organization, state: state, scoped_type: scope) }

      context "when everything is OK" do
        let(:my_description) { ::Faker::Lorem.sentence(word_count: 25) }

        it { is_expected.to be_valid }
      end

      context "when description contains an img tag" do
        let(:my_description) { '<p>description&lt;img src=\"invalid.jpg\" onerror=\"alert();\"&gt;</p>' }

        it { is_expected.to be_invalid }
      end
    end
  end
end
