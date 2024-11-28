# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Meetings
    module Directory
      describe ApplicationHelper do
        let(:helper) do
          Class.new(ActionView::Base) do
            include ApplicationHelper
            include CheckBoxesTreeHelper
            include TranslatableAttributes
          end.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, [])
        end
        let!(:organization) { create(:organization) }
        let!(:parent_scope) { create(:scope, organization: organization) }
        let!(:scope_one) { create(:scope, organization: organization, parent: parent_scope, weight: 1) }
        let!(:scope_two) { create(:scope, organization: organization, parent: parent_scope, weight: 2) }
        let!(:scope_three) { create(:scope, organization: organization, parent: parent_scope, weight: 3) }

        before do
          allow(helper).to receive(:current_organization).and_return(organization)
        end

        describe "#directory_filter_scopes_values" do
          let(:root) { helper.directory_filter_scopes_values }
          let(:leaf) { root.leaf }
          let(:nodes) { root.node }

          context "when the organization has a scope with children" do
            it "returns all the children ordered by weight" do
              expect(root).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
              expect(nodes.last.node.count).to eq(3)
              expect(nodes.last.node.first.leaf.label).to eq(scope_one.name["en"])
              expect(nodes.last.node.last.leaf.label).to eq(scope_three.name["en"])
            end

            context "and the weight of scope's children changes" do
              it "returns the children ordered by the new weight" do
                scope_one.update(weight: 4)
                expect(root).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
                expect(nodes.last.node.count).to eq(3)
                expect(nodes.last.node.first.leaf.label).to eq(scope_two.name["en"])
                expect(nodes.last.node.last.leaf.label).to eq(scope_one.name["en"])
              end
            end
          end
        end
      end
    end
  end
end
