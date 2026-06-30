# frozen_string_literal: true

require "spec_helper"

describe "Participatory process landing page content blocks update" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:participatory_process) { create(:participatory_process, organization:) }
  let!(:content_block) do
    create(:content_block,
           manifest_name: "hero",
           scope_name: "participatory_process_homepage",
           scoped_resource_id: participatory_process.id,
           organization:)
  end

  before do
    login_as user, scope: :user
    host! organization.host
  end

  def signed_id_for(file_path, content_type)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(file_path),
      filename: File.basename(file_path),
      content_type:
    )
    blob.signed_id
  end

  context "when uploading an oversized image" do
    it "does not crash and shows the validation error on re-render" do
      signed_id = signed_id_for(Decidim::Dev.asset("5000x5000.png"), "image/png")

      patch decidim_admin_participatory_processes.participatory_process_landing_page_content_block_path(participatory_process, content_block),
            params: {
              content_block: {
                settings: { button_text_fr: "Test" },
                images: { background_image: signed_id }
              }
            }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("We're sorry, but something went wrong")
      expect(response.body).to include("Images container")
      expect(content_block.reload.images_container.background_image).not_to be_attached
    end
  end

  context "when uploading a valid image" do
    it "saves successfully" do
      signed_id = signed_id_for(Decidim::Dev.asset("city.jpeg"), "image/jpeg")

      patch decidim_admin_participatory_processes.participatory_process_landing_page_content_block_path(participatory_process, content_block),
            params: {
              content_block: {
                settings: { button_text_fr: "Test" },
                images: { background_image: signed_id }
              }
            }

      expect(response).to redirect_to(decidim_admin_participatory_processes.edit_participatory_process_landing_page_path(participatory_process))
      expect(content_block.reload.images_container.background_image).to be_attached
    end
  end
end
