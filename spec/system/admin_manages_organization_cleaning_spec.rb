# frozen_string_literal: true

# # frozen_string_literal: true
#
# require "spec_helper"
#
# describe "AdminManagesOrganizationCleaning" do
#   let(:organization) { create(:organization) }
#   let(:user) { create(:user, :admin, :confirmed, organization:) }
#
#   before do
#     switch_to_host(organization.host)
#     login_as user, scope: :user
#   # end
#
#   describe "edit" do
#     it "updates the values from the form" do
#       visit decidim_admin.edit_organization_cleaner_path
#
#       expect(page).to have_content("Enable admin logs deletion")
#       expect(page).to have_content("Delete admin logs after")
#       expect(page).to have_content("Enable inactive users deletion")
#       expect(page).to have_content("Delete inactive users x days after")
#       expect(page).to have_content("Send email to inactive users before deletion")
#
#       find(:css, "input[name='organization[delete_admin_logs]'").set(true)
#       fill_in "Delete admin logs after", with: 365
#       find(:css, "input[name='organization[delete_inactive_users]'").set(true)
#       fill_in "Delete inactive users x days after", with: 30
#       fill_in "Send email to inactive users before deletion", with: 365
#
#       click_link_or_button "Update"
#       expect(page).to have_content("updated successfully")
#     end
#   end
# end
