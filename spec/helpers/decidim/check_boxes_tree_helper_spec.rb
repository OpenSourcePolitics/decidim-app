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

    describe "#filter_global_scopes_values" do
      let(:root) { helper.filter_global_scopes_values }
      let(:leaf) { helper.filter_global_scopes_values.leaf }
      let(:nodes) { helper.filter_global_scopes_values.node }

      it "returns the global scope" do
        expect(leaf.value).to eq("")
        expect(nodes.count).to eq(1)
        expect(nodes.first).to be_a(Decidim::CheckBoxesTreeHelper::TreePoint)
        expect(nodes.first.value).to eq("global")
      end

      context "when there is a scope with subscopes" do
        let!(:scope) { create(:scope, organization:) }
        let!(:subscopes) { create_list(:subscope, 5, parent: scope) }

        it "returns the global scope, the scope and subscopes" do
          expect(leaf.value).to eq("")
          expect(nodes.count).to eq(2)
          expect(nodes.first).to be_a(Decidim::CheckBoxesTreeHelper::TreePoint)
          expect(nodes.first.value).to eq("global")
          expect(nodes[1]).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
          expect(nodes[1].leaf.value).to eq(scope.id.to_s)
          expect(nodes[1].node.count).to eq(5)
        end
      end

      context "when there is weight in the scopes" do
        let!(:scope) { create(:scope, organization:) }
        let!(:subscopes) { create_list(:subscope, 5, parent: scope) }

        before do
          subscopes.shuffle.each_with_index { |subscope, index| subscope.update!(weight: index) }
        end

        it "returns the subscopes sorted by weight" do
          expected_ids = subscopes.sort_by(&:weight).map(&:id).map(&:to_s)
          scope_node = helper.filter_global_scopes_values.node.find { |n| n.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) }
          actual_values = scope_node.node.map do |node|
            node.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) ? node.leaf.value : node.value
          end
          expect(actual_values).to eq(expected_ids)
        end

        it "assigns weights correctly after shuffle" do
          weights = subscopes.map(&:weight)
          expect(weights).to contain_exactly(0, 1, 2, 3, 4)
        end
      end

      context "when there are multiple top-level scopes" do
        let!(:scope1) { create(:scope, organization:, weight: 2) }
        let!(:scope2) { create(:scope, organization:, weight: 1) }
        let!(:scope3) { create(:scope, organization:, weight: 3) }

        it "returns top-level scopes sorted by weight" do
          scope_nodes = helper.filter_global_scopes_values.node.select { |n| n.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) }
          actual_ids = scope_nodes.map { |node| node.leaf.value.to_i }
          expected_ids = [scope2.id, scope1.id, scope3.id]
          expect(actual_ids).to eq(expected_ids)
        end
      end

      context "when there are nested subscopes with weights" do
        let!(:scope) { create(:scope, organization:, weight: 1) }
        let!(:subscope1) { create(:subscope, parent: scope, weight: 2) }
        let!(:subscope2) { create(:subscope, parent: scope, weight: 1) }
        let!(:sub_subscope1) { create(:subscope, parent: subscope1, weight: 2) }
        let!(:sub_subscope2) { create(:subscope, parent: subscope1, weight: 1) }

        it "returns nested subscopes sorted by weight at each level" do
          scope_node = helper.filter_global_scopes_values.node.find { |n| n.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) }

          first_level_ids = scope_node.node.map do |node|
            node.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) ? node.leaf.value.to_i : node.value.to_i
          end
          expect(first_level_ids).to eq([subscope2.id, subscope1.id])

          second_level_node = scope_node.node.find { |n| n.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) && n.leaf.value.to_i == subscope1.id }
          second_level_ids = second_level_node.node.map do |node|
            node.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) ? node.leaf.value.to_i : node.value.to_i
          end
          expect(second_level_ids).to eq([sub_subscope2.id, sub_subscope1.id])
        end
      end

      context "when scopes have the same weight" do
        let!(:scope) { create(:scope, organization:) }
        let!(:subscope1) { create(:subscope, parent: scope, weight: 1, name: { en: "B Scope" }) }
        let!(:subscope2) { create(:subscope, parent: scope, weight: 1, name: { en: "A Scope" }) }
        let!(:subscope3) { create(:subscope, parent: scope, weight: 1, name: { en: "C Scope" }) }

        it "maintains stable sort order for same weights" do
          scope_node = helper.filter_global_scopes_values.node.find { |n| n.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) }
          actual_ids = scope_node.node.map do |node|
            node.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) ? node.leaf.value.to_i : node.value.to_i
          end

          expect(actual_ids.count).to eq(3)
          expect(actual_ids).to include(subscope1.id, subscope2.id, subscope3.id)
        end
      end

      context "when scopes have nil weights" do
        let!(:scope) { create(:scope, organization:) }
        let!(:subscope_with_weight) { create(:subscope, parent: scope, weight: 2) }
        let!(:subscope_without_weight) { create(:subscope, parent: scope, weight: nil) }

        it "handles nil weights gracefully by treating them as 0" do
          expect { helper.filter_global_scopes_values }.not_to raise_error

          scope_node = helper.filter_global_scopes_values.node.find { |n| n.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) }
          actual_ids = scope_node.node.map do |node|
            node.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) ? node.leaf.value.to_i : node.value.to_i
          end

          expect(actual_ids).to eq([subscope_without_weight.id, subscope_with_weight.id])
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
        let(:root) { helper.filter_areas_values }
        let(:leaf) { helper.filter_areas_values.leaf }
        let(:nodes) { helper.filter_areas_values.node }

        it "returns all the areas" do
          expect(root).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
          expect(leaf.value).to eq("")
          expect(leaf.label).to eq("All")
          expect(nodes.count).to eq(2)
        end

        it "returns TreeNode structure for each area" do
          expect(nodes).to all(be_a(Decidim::CheckBoxesTreeHelper::TreeNode))
        end
      end

      context "when areas have area types" do
        let!(:area_type) { create(:area_type, organization:) }
        let!(:area1) { create(:area, organization:, area_type:) }
        let!(:area2) { create(:area, organization:, area_type:) }

        before do
          allow(helper).to receive(:areas_for_select).with(organization).and_return([area_type])
        end

        it "returns areas grouped by type" do
          expect(root).to be_a(Decidim::CheckBoxesTreeHelper::TreeNode)
          expect(root.node.count).to eq(1)
        end
      end

      context "when organization has many areas" do
        let!(:areas) { create_list(:area, 10, organization:) }

        it "returns all areas without pagination" do
          expect(root.node.count).to eq(10)
        end
      end
    end

    describe "#filter_scopes_values_from" do
      context "when given empty scopes" do
        let(:scopes) { [] }
        let(:test_participatory_space) { nil }

        it "returns only the root with global scope" do
          result = helper.send(:filter_scopes_values_from, scopes, test_participatory_space)
          expect(result.leaf.value).to eq("")
          expect(result.node.count).to eq(1)
          expect(result.node.first.value).to eq("global")
        end
      end

      context "when participatory_space has a scope" do
        let!(:scope) { create(:scope, organization:) }
        let(:test_participatory_space) { create(:participatory_process, organization:, scope:) }
        let(:scopes) { [scope] }

        it "does not include global scope" do
          result = helper.send(:filter_scopes_values_from, scopes, test_participatory_space)
          global_point = result.node.find { |n| n.is_a?(Decidim::CheckBoxesTreeHelper::TreePoint) && n.value == "global" }
          expect(global_point).to be_nil
        end
      end
    end

    describe "#scope_children_to_tree" do
      context "when scope has no children" do
        let!(:scope) { create(:scope, organization:) }

        it "returns nil" do
          result = helper.send(:scope_children_to_tree, scope)
          expect(result).to be_nil
        end
      end

      context "when scope has children" do
        let!(:scope) { create(:scope, organization:) }
        let!(:subscopes) { create_list(:subscope, 3, parent: scope) }

        it "returns array of TreeNodes" do
          result = helper.send(:scope_children_to_tree, scope)
          expect(result).to be_an(Array)
          expect(result.count).to eq(3)
          expect(result).to all(be_a(Decidim::CheckBoxesTreeHelper::TreeNode))
        end
      end

      context "when scope has deeply nested children" do
        let!(:scope) { create(:scope, organization:) }
        let!(:subscope) { create(:subscope, parent: scope) }
        let!(:sub_subscope) { create(:subscope, parent: subscope) }
        let!(:sub_sub_subscope) { create(:subscope, parent: sub_subscope) }

        it "recursively builds the tree" do
          result = helper.send(:scope_children_to_tree, scope)
          expect(result.count).to eq(1)

          level2 = result.first.node
          expect(level2).to be_an(Array)
          expect(level2.count).to eq(1)

          level3 = level2.first.node
          expect(level3).to be_an(Array)
          expect(level3.count).to eq(1)
        end
      end

      context "when scope_type_max_depth is set" do
        let!(:scope_type) { create(:scope_type, organization:) }
        let!(:scope) { create(:scope, organization:, scope_type:) }
        let!(:subscope) { create(:subscope, parent: scope, scope_type:) }
        let(:test_participatory_space) { create(:participatory_process, organization:) }

        before do
          allow(helper).to receive(:current_participatory_space).and_return(test_participatory_space)
          allow(test_participatory_space).to receive(:scope_type_max_depth).and_return(scope_type)
        end

        it "stops at max depth" do
          result = helper.send(:scope_children_to_tree, scope, test_participatory_space)
          expect(result).to be_nil
        end
      end
    end

    describe "integration with translated attributes" do
      context "when scopes have multiple locales" do
        let!(:scope) { create(:scope, organization:, name: { en: "English", fr: "Français" }) }
        let!(:subscope) { create(:subscope, parent: scope, name: { en: "Sub English", fr: "Sub Français" }) }

        it "uses translated_attribute helper" do
          result = helper.filter_global_scopes_values
          scope_node = result.node.find { |n| n.is_a?(Decidim::CheckBoxesTreeHelper::TreeNode) }

          expect(scope_node.leaf.label).to be_present
        end
      end
    end
  end
end
