# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe CheckBoxesTreeHelper do
    let(:helper) do
      Class.new(ActionView::Base) do
        include CheckBoxesTreeHelper
        include TranslatableAttributes
      end.new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, [])
    end

    let!(:organization) { create(:organization) }
    let!(:participatory_space) { create(:participatory_process, organization:) }
    let!(:component) { create(:component, participatory_space:) }

    before do
      allow(helper).to receive(:current_participatory_space).and_return(participatory_space)
      allow(helper).to receive(:current_component).and_return(component)
      allow(helper).to receive(:current_organization).and_return(organization)
      allow(helper).to receive(:areas_for_select).with(organization).and_return(organization.areas)
    end

    describe "#filter_scopes_values" do
      let(:root) { helper.filter_scopes_values }
      let(:leaf) { helper.filter_scopes_values.leaf }
      let(:nodes) { helper.filter_scopes_values.node }

      context "when the participatory space does not have a scope" do
        it "returns the global scope" do
          expect(leaf.value).to eq("")
          expect(nodes.count).to eq(1)
          expect(nodes.first).to be_a(Decidim::CheckBoxesTreeHelper::TreePoint)
          expect(nodes.first.value).to eq("global")
        end
      end

      context "when the participatory space has a scope with subscopes" do
        let(:participatory_space) { create(:participatory_process, :with_scope, organization:) }
        let!(:subscopes) { create_list(:subscope, 5, parent: participatory_space.scope) }

        it "returns all the subscopes" do
          expect(leaf.value).to eq("")
          expect(root).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
          expect(root.node.count).to eq(5)
        end
      end

      context "when the component does not have a scope" do
        before do
          component.update!(settings: { scopes_enabled: true, scope_id: nil })
        end

        it "returns the global scope" do
          expect(leaf.value).to eq("")
          expect(nodes.count).to eq(1)
          expect(nodes.first).to be_a(Decidim::CheckBoxesTreeHelper::TreePoint)
          expect(nodes.first.value).to eq("global")
        end
      end

      context "when the component has a scope with subscopes" do
        let(:participatory_space) { create(:participatory_process, :with_scope, organization:) }
        let!(:subscopes) { create_list(:subscope, 5, parent: participatory_space.scope) }

        before do
          component.update!(settings: { scopes_enabled: true, scope_id: participatory_space.scope.id })
        end

        it "returns all the subscopes" do
          expect(leaf.value).to eq("")
          expect(root).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
          expect(root.node.count).to eq(5)
        end
      end
    end

    describe "#filter_areas_values" do
      let(:root) { helper.filter_areas_values }

      context "when the organization does not have areas" do
        it "does not return any area" do
          expect(root).to be_nil
        end
      end

      context "when the organization has areas" do
        let!(:areas) { create_list(:area, 2, organization:) }
        let(:participatory_space) { create(:participatory_process, organization:) }
        let(:root) { helper.filter_areas_values }
        let(:leaf) { helper.filter_areas_values.leaf }
        let(:nodes) { helper.filter_areas_values.node }

        it "returns all the areas" do
          expect(root).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
          expect(leaf.value).to eq("")
          expect(leaf.label).to eq("All")
          expect(nodes.count).to eq(2)
        end
      end
    end

    context "when there is weight in the scopes" do
      let(:participatory_space) { create(:participatory_process, :with_scope, organization:) }
      let!(:subscopes) { create_list(:subscope, 5, parent: participatory_space.scope) }

      before do
        subscopes.shuffle.each_with_index { |subscope, index| subscope.update!(weight: index) }
      end

      it "returns the subscopes sorted by weight" do
        expected_ids = subscopes.sort_by(&:weight).map { |subscope| subscope.id.to_s }
        actual_values = helper.filter_scopes_values.node.map { |node| node.values.first.value.to_s }
        expect(actual_values).to eq(expected_ids)
      end

      it "assigns weights correctly after shuffle" do
        weights = subscopes.map(&:weight)
        expect(weights).to contain_exactly(0, 1, 2, 3, 4)
      end

      it "sorts subscopes correctly by weight" do
        sorted_subscopes = subscopes.sort_by(&:weight)
        expect(subscopes.sort_by(&:weight)).to eq(sorted_subscopes)
      end

      it "checks that the helper method returns sorted subscopes" do
        sorted_subscopes = subscopes.sort_by(&:weight).map { |subscope| subscope.id.to_s }
        expect(helper.filter_scopes_values.node.map { |node| node.values.first.value.to_s }).to eq(sorted_subscopes)
      end

      it "returns false when the subscopes are not sorted by weight" do
        unsorted_subscopes = subscopes.shuffle
        unsorted_values = unsorted_subscopes.map { |subscope| subscope.id.to_s }
        expect(helper.filter_scopes_values.node.map { |node| node.values.first.value.to_s }).not_to eq(unsorted_values)
      end

      it "returns false when subscopes are not sorted in ascending order of weight" do
        reversed_subscopes = subscopes.sort_by(&:weight).reverse
        reversed_values = reversed_subscopes.map { |subscope| subscope.id.to_s }
        expect(helper.filter_scopes_values.node.map { |node| node.values.first.value.to_s }).not_to eq(reversed_values)
      end
    end
  end
end
