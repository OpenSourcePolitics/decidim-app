# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    describe ProposalSerializer do
      subject do
        described_class.new(proposal)
      end

      let!(:organization) do
        create(:organization, available_authorizations: ["phone_authorization_handler"])
      end

      let!(:proposal) { create(:proposal, :accepted) }
      let!(:category) { create(:category, participatory_space: component.participatory_space) }
      let!(:scope) { create(:scope, organization: component.participatory_space.organization) }
      let(:participatory_process) { component.participatory_space }
      let(:component) { proposal.component }

      let!(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
      let(:meetings) { create_list(:meeting, 2, component: meetings_component) }

      let!(:proposals_component) { create(:component, manifest_name: "proposals", participatory_space: participatory_process) }

      let!(:authorization) do
        create(
          :authorization,
          id: 1,
          name: "phone_authorization_handler",
          user: proposal.creator_author,
          metadata: {
            phone_number: "0644444444"
          }
        )
      end

      let(:other_proposals) { create_list(:proposal, 2, component: proposals_component) }
      let(:expected_answer) do
        answer = proposal.answer
        Decidim.available_locales.each_with_object({}) do |locale, result|
          result[locale.to_s] = if answer.is_a?(Hash)
                                  answer[locale.to_s] || ""
                                else
                                  ""
                                end
        end
      end

      before do
        proposal.update!(category: category)
        proposal.update!(scope: scope)
        proposal.link_resources(meetings, "proposals_from_meeting")
        proposal.link_resources(other_proposals, "copied_from_component")
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "serializes the id" do
          expect(serialized).to include(id: proposal.id)
        end

        it "serializes the category" do
          expect(serialized[:category]).to include(id: category.id)
          expect(serialized[:category]).to include(name: category.name)
        end

        it "serializes the scope" do
          expect(serialized[:scope]).to include(id: scope.id)
          expect(serialized[:scope]).to include(name: scope.name)
        end

        it "serializes the title" do
          expect(serialized).to include(title: proposal.title)
        end

        it "serializes the body" do
          expect(serialized).to include(body: proposal.body)
        end

        it "serializes the amount of supports" do
          expect(serialized).to include(supports: proposal.proposal_votes_count)
        end

        it "serializes the amount of comments" do
          expect(serialized).to include(comments: proposal.comments.count)
        end

        it "serializes the date of creation" do
          expect(serialized).to include(published_at: proposal.published_at)
        end

        it "serializes the url" do
          expect(serialized[:url]).to include("http", proposal.id.to_s)
        end

        it "serializes the component" do
          expect(serialized[:component]).to include(id: proposal.component.id)
        end

        it "serializes the meetings" do
          expect(serialized[:meeting_urls].length).to eq(2)
          expect(serialized[:meeting_urls].first).to match(%r{http.*/meetings})
        end

        it "serializes the participatory space" do
          expect(serialized[:participatory_space]).to include(id: participatory_process.id)
          expect(serialized[:participatory_space][:url]).to include("http", participatory_process.slug)
        end

        it "serializes the state" do
          expect(serialized).to include(state: proposal.state)
        end

        it "serializes the reference" do
          expect(serialized).to include(reference: proposal.reference)
        end

        it "serializes the answer" do
          expect(serialized).to include(answer: expected_answer)
        end

        it "serializes the amount of attachments" do
          expect(serialized).to include(attachments: proposal.attachments.count)
        end

        it "serializes the endorsements" do
          expect(serialized[:endorsements]).to include(total_count: proposal.endorsements.count)
          expect(serialized[:endorsements]).to include(user_endorsements: proposal.endorsements.for_listing.map { |identity| identity.normalized_author&.name })
        end

        it "serializes related proposals" do
          expect(serialized[:related_proposals].length).to eq(2)
          expect(serialized[:related_proposals].first).to match(%r{http.*/proposals})
        end

        it "doesn't serialize author's data" do
          expect(serialized).not_to include(:author)
        end

        context "when admin exports proposal" do
          subject do
            described_class.new(proposal, false)
          end

          let(:serialized) { subject.serialize }

          it "serializes author" do
            expect(serialized).to include(:author)
          end

          it "data in author are not empty" do
            expect(serialized[:author][:name]).not_to be_empty
            expect(serialized[:author][:nickname]).not_to be_empty
            expect(serialized[:author][:email]).not_to be_empty
            expect(serialized[:author][:phone_number]).not_to be_empty
          end

          context "when proposal was created by admin from backoffice" do
            let!(:admin) { create(:user, :admin) }

            before do
              proposal.coauthorships.clear
              proposal.add_coauthor(proposal.organization)
            end

            it "serializes author" do
              expect(serialized).to include(:author)
            end

            it "author's data are empty" do
              expect(serialized[:author][:name]).to be_empty
              expect(serialized[:author][:nickname]).to be_empty
              expect(serialized[:author][:email]).to be_empty
              expect(serialized[:author][:phone_number]).to be_empty
            end
          end

          context "when there is no authorization for user" do
            let(:authorization) { nil }

            it "author's phone number should be empty" do
              expect(serialized[:author][:name]).not_to be_empty
              expect(serialized[:author][:nickname]).not_to be_empty
              expect(serialized[:author][:email]).not_to be_empty
              expect(serialized[:author][:phone_number]).to be_empty
            end
          end
        end

        context "with proposal having an answer" do
          let!(:proposal) { create(:proposal, :with_answer) }

          it "serializes the answer" do
            expect(serialized).to include(answer: expected_answer)
          end
        end
      end
    end
  end
end
