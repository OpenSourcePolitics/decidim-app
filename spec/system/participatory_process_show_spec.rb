# frozen_string_literal: true

require "spec_helper"
require "decidim/core/test/shared_examples/has_contextual_help"

describe "Participatory Process show page" do
  let(:organization) { create(:organization) }
  let(:hashtag) { true }
  let(:base_description) { { en: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed non risus. Suspendisse lectus tortor, dignissim sit amet, adipiscing nec, ultricies sed, dolor. Cras elementum ultrices diam. Maecenas ligula massa, varius a, semper congue, euismod non, mi. Proin porttitor, orci nec nonummy molestie, enim est eleifend mi, non fermentum diam nisl sit amet erat. Duis semper. Duis arcu massa, scelerisque vitae, consequat in, pretium a, enim. Pellentesque congue. Ut in risus volutpat libero pharetra tempor. Cras vestibulum bibendum augue. Praesent egestas leo in pede. Praesent blandit odio eu enim. Pellentesque sed dui ut augue blandit sodales. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Aliquam nibh. Mauris ac mauris sed pede pellentesque fermentum. Maecenas adipiscing ante non diam sodales hendrerit. Ut velit mauris, egestas sed, gravida nec, ornare ut, mi. Aenean ut orci vel massa suscipit pulvinar. Nulla sollicitudin. Fusce varius, ligula non tempus aliquam, nunc turpis ullamcorper nibh, in tempus sapien eros vitae ligula. Pellentesque rhoncus nunc et augue. Integer id felis. Curabitur aliquet pellentesque diam. Integer quis metus vitae elit lobortis egestas. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Morbi vel erat non mauris convallis vehicula. Nulla et sapien. Integer tortor tellus, aliquam faucibus, convallis id, congue eu, quam. Mauris ullamcorper felis vitae erat. Proin feugiat, augue non elementum posuere, metus purus iaculis lectus, et tristique ligula justo vitae magna." } }
  let(:short_description) { { en: "Short description", ca: "Descripció curta", es: "Descripción corta" } }

  let(:base_process) do
    create(
      :participatory_process,
      :active,
      organization:,
      description: base_description,
      short_description:
    )
  end

  before do
    switch_to_host(organization.host)
  end

  context "when going to the participatory process page" do
    let!(:participatory_process) { base_process }
    let!(:proposals_component) { create(:component, :published, participatory_space: participatory_process, manifest_name: :proposals) }
    let!(:meetings_component) { create(:component, :unpublished, participatory_space: participatory_process, manifest_name: :meetings) }

    before do
      create_list(:proposal, 3, component: proposals_component)
      allow(Decidim).to receive(:component_manifests).and_return([proposals_component.manifest, meetings_component.manifest])
    end

    describe "page title" do
      it "has the participatory process title in the show page" do
        visit decidim_participatory_processes.participatory_process_path(participatory_process)

        expect(page).to have_title("#{translated(participatory_process.title)} - #{translated(organization.name)}")
      end
    end

    it_behaves_like "editable content for admins" do
      let(:target_path) { decidim_participatory_processes.participatory_process_path(participatory_process) }
    end

    context "when requesting the participatory process path" do
      let(:blocks_manifests) { [] }

      before do
        blocks_manifests.each do |manifest_name|
          create(:content_block, organization:, scope_name: :participatory_process_homepage, manifest_name:, scoped_resource_id: participatory_process.id)
        end
        visit decidim_participatory_processes.participatory_process_path(participatory_process)
      end

      context "when requesting the process path" do
        context "when hero, main_data and phase and duration blocks are enabled" do
          let(:blocks_manifests) { [:hero, :main_data, :extra_data, :metadata] }

          it "shows the details of the given process" do
            within "[data-content]" do
              expect(page).to have_content("About this process")
              expect(page).to have_content(translated(participatory_process.title, locale: :en))
              expect(page).to have_content(translated(participatory_process.subtitle, locale: :en))
              expect(page).to have_content(translated(participatory_process.description, locale: :en))
              expect(page).to have_content(translated(participatory_process.short_description, locale: :en))
              expect(page).to have_content(translated(participatory_process.meta_scope, locale: :en))
              expect(page).to have_content(translated(participatory_process.developer_group, locale: :en))
              expect(page).to have_content(translated(participatory_process.local_area, locale: :en))
              expect(page).to have_content(translated(participatory_process.target, locale: :en))
              expect(page).to have_content(translated(participatory_process.participatory_scope, locale: :en))
              expect(page).to have_content(translated(participatory_process.participatory_structure, locale: :en))
              expect(page).to have_content(I18n.l(participatory_process.start_date, format: :decidim_short_with_month_name_short))
              expect(page).to have_content(I18n.l(participatory_process.end_date, format: :decidim_short_with_month_name_short))
              expect(page).to have_content(participatory_process.hashtag)
              expect(page).to have_content("Show less")
            end
          end

          it "shows less or more description when clicking on button" do
            expect(page).to have_css('button[data-controls^="panel-view-more"][aria-expanded="true"]')
            click_link_or_button "Show less"
            within "[data-content]" do
              expect(page).to have_css('div[id^="panel-view-more"][aria-hidden="true"]')
              expect(page).to have_css('button[data-controls^="panel-view-more"][aria-expanded="false"]')
            end
            click_link_or_button "More information"
            within "[data-content]" do
              expect(page).to have_css('div[id^="panel-view-more"][aria-hidden="false"]')
              expect(page).to have_css('button[data-controls^="panel-view-more"][aria-expanded="true"]')
            end
          end
        end
      end
    end
  end
end
