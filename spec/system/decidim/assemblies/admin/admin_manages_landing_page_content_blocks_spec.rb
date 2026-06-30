# frozen_string_literal: true

require "spec_helper"

describe "Admin manages assembly landing page content blocks" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:assembly) { create(:assembly, organization:) }
  let!(:content_block) do
    create(:content_block,
           manifest_name: "hero",
           scope_name: "assembly_homepage",
           scoped_resource_id: assembly.id,
           organization:)
  end

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_assemblies.edit_assembly_landing_page_content_block_path(assembly, content_block)
  end

  context "when uploading an oversized background image" do
    it "shows a validation error instead of crashing" do
      dynamically_attach_file(:content_block_images_background_image, Decidim::Dev.asset("5000x5000.png"))

      within ".edit_content_block" do
        find("*[type=submit]").click
      end

      expect(page).to have_no_content("We're sorry, but something went wrong")
      expect(page).to have_content("Images container is invalid")
    end
  end

  context "when uploading a valid background image" do
    it "saves the content block and redirects to the landing page" do
      dynamically_attach_file(:content_block_images_background_image, Decidim::Dev.asset("city.jpeg"))

      within ".edit_content_block" do
        find("*[type=submit]").click
      end

      expect(page).to have_no_content("Images container is invalid")
      expect(page).to have_current_path(decidim_admin_assemblies.edit_assembly_landing_page_path(assembly))
      expect(content_block.reload.images_container.background_image).to be_attached
    end
  end
end
