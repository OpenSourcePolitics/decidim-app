# frozen_string_literal: true

# This migration comes from decidim (originally 20180323102631)

class ChangeEventNameAndClassToRenameToPublishProposalEvent < ActiveRecord::Migration[5.1]
  def up
    Decidim::Notification.where(event_name: "decidim.events.proposals.proposal_created")
                         .update_all(event_name: "decidim.events.proposals.proposal_published", event_class: "Decidim::Proposals::PublishProposalEvent")
  end

  def down
    Decidim::Notification.where(event_name: "decidim.events.proposals.proposal_published")
                         .update_all(event_name: "decidim.events.proposals.proposal_created", event_class: "Decidim::Proposals::CreateProposalEvent")
  end
end
