# frozen_string_literal: true

require "spec_helper"

module Decidim::Exporters
  describe OpenDataBlockedUserSerializer do
    subject { described_class.new(resource) }

    let(:organization) { create(:organization) }
    let(:serialized) { subject.serialize }

    describe "#serialize" do
      context "when the user has an associated block" do
        let!(:user_block) { create(:user_block, organization:) }
        let(:resource) { create(:user_moderation, user: user_block.user) }

        it "includes the block reasons and the blocking user" do
          expect(serialized).to include(
            block_reasons: user_block.justification,
            blocking_user: user_block.blocking_user.presenter.name
          )
        end
      end

      # decidim-spam_detection 4.1.0 created a UserBlock but never set
      # `block_id`, so `blocking` is nil for users it blocked.
      context "when the user is blocked but has no associated block" do
        let(:user) { create(:user, :blocked, :confirmed, organization:) }
        let(:resource) { create(:user_moderation, user:) }

        before { user.update!(block_id: nil, blocked_at: Time.current) }

        it "serializes the block fields as nil and keeps the rest" do
          expect(serialized).to include(block_reasons: nil, blocking_user: nil, user_id: user.id, about: user.about)
        end
      end
    end
  end
end
