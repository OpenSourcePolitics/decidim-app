# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe ProposalForm do
      subject { form }

      let(:organization) { create(:organization, available_locales: [:en]) }
      let!(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
      let(:component) { create(:proposal_component, participatory_space:, settings:) }
      let!(:category) { create(:category, participatory_space:) }
      let(:title) { "More sidewalks and less roads!" }
      let(:body) { "Everything would be better" }
      let(:body_template) { nil }
      let(:author) { create(:user, organization:) }
      let(:user_group) { create(:user_group, :verified, users: [author], organization:) }
      let(:user_group_id) { user_group.id }
      let(:parent_scope) { create(:scope, organization:) }
      let!(:scope) { create(:subscope, parent: parent_scope) }
      let(:category_id) { category.try(:id) }
      let(:scope_id) { scope.try(:id) }
      let(:latitude) { 40.1234 }
      let(:longitude) { 2.1234 }
      let(:address) { nil }
      let(:suggested_hashtags) { [] }
      let(:attachment_params) { nil }
      let(:meeting_as_author) { false }

      let(:params) do
        {
          title:,
          body:,
          body_template:,
          author:,
          category_id:,
          scope_id:,
          address:,
          meeting_as_author:,
          attachment: attachment_params,
          suggested_hashtags:
        }
      end

      let(:form) do
        described_class.from_params(params).with_context(
          current_component: component,
          current_organization: component.organization,
          current_participatory_space: participatory_space
        )
      end

      describe "whithout category and without scope" do
        let!(:category) { nil }
        let(:settings) { { scopes_enabled: false, require_category: true, require_scope: true } }

        context "when no category_id" do
          let(:category_id) { nil }

          it { is_expected.to be_valid }
        end

        context "when no scope_id" do
          let(:scope_id) { nil }

          it { is_expected.to be_valid }
        end
      end

      describe "with category and scope" do
        let!(:settings) { { scopes_enabled: true, require_category: true, require_scope: true } }

        describe "scope" do
          let(:current_component) { component }

          it_behaves_like "a scopable resource"
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "when there is no title" do
          let(:title) { nil }

          it { is_expected.to be_invalid }

          it "only adds errors to this field" do
            subject.valid?
            expect(subject.errors.attribute_names).to eq [:title]
          end
        end

        context "when the title is too long" do
          let(:title) { "A" * 200 }

          it { is_expected.to be_invalid }
        end

        context "when the title is the minimum length" do
          let(:title) { "Length is right" }

          it { is_expected.to be_valid }
        end

        context "when the body is not etiquette-compliant" do
          let(:body) { "A" }

          it { is_expected.to be_invalid }
        end

        context "when there is no body" do
          let(:body) { nil }

          it { is_expected.to be_invalid }
        end

        context "when the body exceeds the permitted length" do
          let(:component) { create(:proposal_component, :with_proposal_length, participatory_space:, proposal_length: allowed_length) }
          let(:allowed_length) { 15 }
          let(:body) { "A body longer than the permitted" }

          it { is_expected.to be_invalid }

          context "with carriage return characters that cause it to exceed" do
            let(:allowed_length) { 80 }
            let(:body) { "This text is just the correct length\r\nwith the carriage return characters removed" }

            it { is_expected.to be_valid }
          end
        end

        context "when there is a body template set" do
          let(:body_template) { "This is the template" }

          it { is_expected.to be_valid }

          context "when the template and the body are the same" do
            let(:body) { body_template }

            it { is_expected.to be_invalid }
          end
        end

        context "when no category_id" do
          let(:category_id) { nil }

          it { is_expected.to be_invalid }
        end

        context "when no scope_id" do
          let(:scope_id) { nil }

          it { is_expected.to be_invalid }
        end

        context "with invalid category_id" do
          let(:category_id) { 987 }

          it { is_expected.to be_invalid }
        end

        context "when geocoding is enabled" do
          let(:component) { create(:proposal_component, :with_geocoding_enabled, participatory_space:) }

          context "when the address is not present" do
            it "does not store the coordinates" do
              expect(subject).to be_valid
              expect(subject.address).to be_nil
              expect(subject.latitude).to be_nil
              expect(subject.longitude).to be_nil
            end
          end

          context "when the address is present" do
            let(:address) { "Some address" }
            let(:params) do
              {
                title:,
                body:,
                body_template:,
                author:,
                category_id:,
                scope_id:,
                address:,
                attachment: attachment_params,
                latitude:,
                longitude:
              }
            end

            before do
              stub_geocoding(address, [latitude, longitude])
            end

            it "validates the address and store its coordinates" do
              expect(subject).to be_valid
              expect(subject.latitude).to eq(latitude)
              expect(subject.longitude).to eq(longitude)
            end
          end

          context "when latitude and longitude are manually set" do
            context "when the has address checkbox is unchecked" do
              it "is valid" do
                expect(subject).to be_valid
                expect(subject.latitude).to be_nil
                expect(subject.longitude).to be_nil
              end
            end

            context "when the proposal is unchanged" do
              let(:previous_proposal) { create(:proposal, address:, component:, decidim_scope_id: scope.id, category:) }
              let(:title) { translated(previous_proposal.title) }
              let(:body) { translated(previous_proposal.body) }
              let(:params) do
                {
                  id: previous_proposal.id,
                  title:,
                  body:,
                  author: previous_proposal.authors.first,
                  category_id: previous_proposal.category.id,
                  scope_id: previous_proposal.scope.id,
                  address:,
                  attachment: previous_proposal.try(:attachment_params),
                  latitude:,
                  longitude:
                }
              end

              it "is valid" do
                expect(subject).to be_valid
                expect(subject.latitude).to eq(latitude)
                expect(subject.longitude).to eq(longitude)
              end
            end
          end
        end

        describe "category" do
          subject { form.category }

          context "when the category exists" do
            it { is_expected.to be_a(Decidim::Category) }
          end

          context "when the category does not exist" do
            let(:category_id) { 7654 }

            it { is_expected.to be_nil }
          end

          context "when the category is from another process" do
            let(:category_id) { create(:category).id }

            it { is_expected.to be_nil }
          end
        end

        it "properly maps category id from model" do
          proposal = create(:proposal, component:, category:)

          expect(described_class.from_model(proposal).category_id).to eq(category_id)
        end

        it "properly maps user group id from model" do
          proposal = create(:proposal, component:, users: [author], user_groups: [user_group])

          expect(described_class.from_model(proposal).user_group_id).to eq(user_group_id)
        end

        context "when the attachment is present" do
          let(:params) do
            {
              :title => title,
              :body => body,
              :author => author,
              :category_id => category_id,
              :scope_id => scope_id,
              :address => address,
              :meeting_as_author => meeting_as_author,
              :suggested_hashtags => suggested_hashtags,
              attachments_key => [Decidim::Dev.test_file("city.jpeg", "image/jpeg")]
            }
          end
          let(:attachments_key) { :add_documents }

          it { is_expected.to be_valid }

          context "when the form has some errors" do
            context "when title is blank" do
              let(:title) { nil }

              it "adds an error to the `:title` field" do
                expect(subject).not_to be_valid
                expect(subject.errors.full_messages).to contain_exactly("Title cannot be blank")
                expect(subject.errors.attribute_names).to contain_exactly(:title)
              end
            end

            context "when title is too short" do
              let(:title) { "Short" }

              it "adds an error to the `:title` field" do
                expect(subject).not_to be_valid
                expect(subject.errors.full_messages).to contain_exactly("Title is too short (under 15 characters)")
                expect(subject.errors.attribute_names).to contain_exactly(:title)
              end
            end
          end
        end

        describe "#extra_hashtags" do
          subject { form.extra_hashtags }

          let(:component) do
            create(
              :proposal_component,
              :with_extra_hashtags,
              participatory_space:,
              suggested_hashtags: component_suggested_hashtags,
              automatic_hashtags: component_automatic_hashtags
            )
          end
          let(:component_automatic_hashtags) { "" }
          let(:component_suggested_hashtags) { "" }

          it { is_expected.to eq([]) }

          context "when there are auto hashtags" do
            let(:component_automatic_hashtags) { "HashtagAuto1 HashtagAuto2" }

            it { is_expected.to eq(%w(HashtagAuto1 HashtagAuto2)) }
          end

          context "when there are some suggested hashtags checked" do
            let(:component_suggested_hashtags) { "HashtagSuggested1 HashtagSuggested2 HashtagSuggested3" }
            let(:suggested_hashtags) { %w(HashtagSuggested1 HashtagSuggested2) }

            it { is_expected.to eq(%w(HashtagSuggested1 HashtagSuggested2)) }
          end

          context "when there are invalid suggested hashtags checked" do
            let(:component_suggested_hashtags) { "HashtagSuggested1 HashtagSuggested2" }
            let(:suggested_hashtags) { %w(HashtagSuggested1 HashtagSuggested3) }

            it { is_expected.to eq(%w(HashtagSuggested1)) }
          end

          context "when there are both suggested and auto hashtags" do
            let(:component_automatic_hashtags) { "HashtagAuto1 HashtagAuto2" }
            let(:component_suggested_hashtags) { "HashtagSuggested1 HashtagSuggested2" }
            let(:suggested_hashtags) { %w(HashtagSuggested2) }

            it { is_expected.to eq(%w(HashtagAuto1 HashtagAuto2 HashtagSuggested2)) }
          end
        end
      end
    end
  end
end
