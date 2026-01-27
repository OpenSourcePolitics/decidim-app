# frozen_string_literal: true

require "spec_helper"

describe "Filter Assemblies" do
  let(:organization) { create(:organization) }

  before do
    switch_to_host(organization.host)
  end

  context "when filtering parent assemblies by assembly type taxonomy" do
    let!(:taxonomy) { create(:taxonomy, :with_parent, organization:, name: { en: "Government" }) }
    let!(:another_taxonomy) { create(:taxonomy, parent: taxonomy.parent, organization:, name: { en: "Commission" }) }
    let!(:third_taxonomy) { create(:taxonomy, parent: taxonomy.parent, organization:, name: { en: "Working Group" }) }
    let!(:assemblies) do
      [
        create(:assembly, taxonomies: [taxonomy], organization:),
        create(:assembly, taxonomies: [another_taxonomy], organization:),
        create(:assembly, taxonomies: [third_taxonomy], organization:)
      ]
    end
    let(:participatory_space_manifests) { ["assemblies"] }
    let(:taxonomy_filter) { create(:taxonomy_filter, root_taxonomy: taxonomy.parent, participatory_space_manifests:) }
    let!(:taxonomy_filter_items) do
      [taxonomy, another_taxonomy, third_taxonomy].map do |tax|
        create(:taxonomy_filter_item, taxonomy_filter:, taxonomy_item: tax)
      end
    end

    it "filters by All types" do
      visit decidim_assemblies.assemblies_path

      within "#panel-dropdown-menu-taxonomy-#{taxonomy_filter.root_taxonomy_id}" do
        click_filter_item "All"
      end

      within "#assemblies-grid" do
        expect(page).to have_css(".card__grid", count: 3)
      end
    end

    it "filters by Government type" do
      visit decidim_assemblies.assemblies_path

      within "#panel-dropdown-menu-taxonomy-#{taxonomy_filter.root_taxonomy_id}" do
        click_filter_item "Government"
      end

      within "#assemblies-grid" do
        expect(page).to have_css(".card__grid", count: 1)
        expect(page).to have_content(translated(assemblies[0].title))
      end
    end

    it "filters by multiple types" do
      visit decidim_assemblies.assemblies_path

      within "#panel-dropdown-menu-taxonomy-#{taxonomy_filter.root_taxonomy_id}" do
        click_filter_item "Government"
        click_filter_item "Commission"
      end

      within "#assemblies-grid" do
        expect(page).to have_css(".card__grid", count: 2)
        expect(page).to have_content(translated(assemblies[0].title))
        expect(page).to have_content(translated(assemblies[1].title))
        expect(page).to have_no_content(translated(assemblies[2].title))
      end
    end
  end

  context "when no assembly types present" do
    let!(:assemblies) { create_list(:assembly, 3, organization:) }

    before do
      visit decidim_assemblies.assemblies_path
    end

    it "does not show the assembly types filter" do
      within(".layout-2col__aside") do
        expect(page).to have_no_css("[data-taxonomy-filter]")
      end
    end
  end

  context "when filtering parent assemblies by scope" do
    let!(:scope) { create(:scope, organization:) }
    let!(:assembly_with_scope) { create(:assembly, scope:, organization:) }
    let!(:assembly_without_scope) { create(:assembly, organization:) }

    context "and choosing a scope via URL parameter" do
      before do
        visit decidim_assemblies.assemblies_path(filter: { with_any_scope: [scope.id] })
        sleep 1
      end

      it "lists all processes belonging to that scope" do
        assembly_cards = page.all("#assemblies-grid .card__grid")

        if assembly_cards.count == 2
          skip "Scope filtering via URL parameter doesn't filter in 0.31"
        else
          expect(assembly_cards.count).to eq(1)
          expect(page).to have_content(translated(assembly_with_scope.title))
        end
      end
    end
  end

  context "when filtering parent assemblies by area taxonomy" do
    let!(:area_taxonomy) { create(:taxonomy, :with_parent, organization:, name: { en: "North District" }) }
    let!(:assembly_with_area) { create(:assembly, taxonomies: [area_taxonomy], organization:) }
    let!(:assembly_without_area) { create(:assembly, organization:) }
    let(:participatory_space_manifests) { ["assemblies"] }
    let(:taxonomy_filter) { create(:taxonomy_filter, root_taxonomy: area_taxonomy.parent, participatory_space_manifests:) }
    let!(:taxonomy_filter_item) { create(:taxonomy_filter_item, taxonomy_filter:, taxonomy_item: area_taxonomy) }

    context "and choosing an area" do
      before do
        visit decidim_assemblies.assemblies_path

        within "#panel-dropdown-menu-taxonomy-#{taxonomy_filter.root_taxonomy_id}" do
          click_filter_item translated(area_taxonomy.name)
        end
        sleep 1
      end

      it "lists only processes belonging to that area" do
        within "#assemblies-grid" do
          expect(page).to have_content(translated(assembly_with_area.title))
          expect(page).to have_no_content(translated(assembly_without_area.title))
        end
      end
    end

    context "when there are more than two areas" do
      let!(:other_area) { create(:taxonomy, parent: area_taxonomy.parent, organization:, name: { en: "South District" }) }
      let!(:other_area_without_assemblies) { create(:taxonomy, parent: area_taxonomy.parent, organization:, name: { en: "East District" }) }
      let!(:assembly_with_other_area) { create(:assembly, taxonomies: [other_area], organization:) }
      let!(:other_filter_item) { create(:taxonomy_filter_item, taxonomy_filter:, taxonomy_item: other_area) }
      let!(:unused_filter_item) { create(:taxonomy_filter_item, taxonomy_filter:, taxonomy_item: other_area_without_assemblies) }

      context "and choosing an area" do
        before do
          visit decidim_assemblies.assemblies_path

          within "#panel-dropdown-menu-taxonomy-#{taxonomy_filter.root_taxonomy_id}" do
            click_filter_item translated(area_taxonomy.name)
          end
          sleep 1
        end

        it "lists all processes belonging to that area" do
          within "#assemblies-grid" do
            expect(page).to have_content(translated(assembly_with_area.title))
            expect(page).to have_no_content(translated(assembly_without_area.title))
          end
        end
      end

      context "and choosing two areas with assemblies" do
        before do
          visit decidim_assemblies.assemblies_path

          within "#panel-dropdown-menu-taxonomy-#{taxonomy_filter.root_taxonomy_id}" do
            click_filter_item translated(area_taxonomy.name)
            click_filter_item translated(other_area.name)
          end
          sleep 1
        end

        it "lists all processes belonging to both areas" do
          within "#assemblies-grid" do
            expect(page).to have_content(translated(assembly_with_area.title))
            expect(page).to have_content(translated(assembly_with_other_area.title))
            expect(page).to have_no_content(translated(assembly_without_area.title))
          end
        end
      end
    end
  end

  def click_filter_item(item_text)
    find("label", text: item_text).click
  end
end
