# frozen_string_literal: true

require "spec_helper"

describe Decidim::Comments::CommentMetadataCell, type: :cell do
  controller Decidim::Comments::CommentsController
  subject { my_cell.call }

  let(:my_cell) { cell("decidim/comments/comment_metadata", comment) }
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let(:component) { create(:component, participatory_space: participatory_process) }
  let(:commentable) { create(:dummy_resource, component:) }
  let(:comment) { create(:comment, commentable:) }
  let(:created_at) { Time.current }

  describe "#items" do
    it "returns an array of items" do
      expect(my_cell.send(:items)).to be_an(Array)
    end

    it "includes the commentable item" do
      expect(my_cell.send(:items)).to include(my_cell.send(:commentable_item))
    end

    it "includes the comments count item" do
      expect(my_cell.send(:items)).to include(my_cell.send(:comments_count_item))
    end

    it "has 3 items" do
      expect(my_cell.send(:items).count).to eq(3)
    end

    context "when comments_count_item is nil" do
      before do
        allow(my_cell).to receive(:comments_count_item).and_return(nil)
      end

      it "does not include the comments count item" do
        expect(my_cell.send(:items)).not_to include(my_cell.send(:comments_count_item))
        expect(my_cell.send(:items).count).to eq(2)
      end
    end
  end
end
