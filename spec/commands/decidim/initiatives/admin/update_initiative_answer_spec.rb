# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    module Admin
      describe UpdateInitiativeAnswer do
        let(:form_klass) { Decidim::Initiatives::Admin::InitiativeAnswerForm }

        context "when valid data" do
          it_behaves_like "update an initiative answer" do
            context "when the user is an admin" do
              let!(:current_user) { create(:user, :admin, organization: initiative.organization) }
              let!(:follower) { create(:user, organization: organization) }
              let!(:follow) { create(:follow, followable: initiative, user: follower) }

              it "notifies the followers for extension and answer" do
                expect(Decidim::EventsManager)
                  .to receive(:publish)
                  .with(
                    event: "decidim.events.initiatives.initiative_extended",
                    event_class: Decidim::Initiatives::ExtendInitiativeEvent,
                    resource: initiative,
                    followers: [follower]
                  )
                  .ordered
                expect(Decidim::EventsManager)
                  .to receive(:publish)
                  .with(
                    event: "decidim.events.initiatives.initiative_answered",
                    event_class: Decidim::Initiatives::AnswerInitiativeEvent,
                    resource: initiative,
                    followers: [follower]
                  )
                  .ordered

                command.call
              end

              context "when the signature end time is not modified" do
                let(:signature_end_date) { initiative.signature_end_date }

                it "doesn't notify the followers" do
                  expect(Decidim::EventsManager).not_to receive(:publish).with(
                    event: "decidim.events.initiatives.initiative_extended",
                    event_class: Decidim::Initiatives::ExtendInitiativeEvent,
                    resource: initiative,
                    followers: [follower]
                  )

                  command.call
                end
              end
            end
          end
        end

        context "when validation failure" do
          let(:organization) { create(:organization) }
          let!(:initiative) { create(:initiative, organization: organization) }
          let!(:form) do
            form_klass
              .from_model(initiative)
              .with_context(current_organization: organization, initiative: initiative)
          end

          let(:command) { described_class.new(initiative, form, initiative.author) }

          it "broadcasts invalid" do
            expect(initiative).to receive(:valid?)
              .at_least(:once)
              .and_return(false)
            expect { command.call }.to broadcast :invalid
          end
        end
      end
    end
  end
end
