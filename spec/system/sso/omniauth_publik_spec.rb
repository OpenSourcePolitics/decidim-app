# frozen_string_literal: true

# # frozen_string_literal: true
#
# require "spec_helper"
#
# describe "Omniauth Publik" do
#   let(:organization) { create(:organization) }
#
#   before do
#     switch_to_host(organization.host)
#     visit decidim.root_path
#   end
#
#   context "when using Publik" do
#     let(:omniauth_hash) do
#       OmniAuth::AuthHash.new(
#         provider: "publik",
#         uid: "123545",
#         info: {
#           nickname: "foobar",
#           name: "Foo Bar",
#           email: "foo@bar.com"
#         }
#       )
#     end
#
#     before do
#       OmniAuth.config.test_mode = true
#       OmniAuth.config.mock_auth[:publik] = omniauth_hash
#       OmniAuth.config.add_camelization "publik", "Publik"
#       OmniAuth.config.request_validation_phase = ->(env) {} if OmniAuth.config.respond_to?(:request_validation_phase)
#     end
#
#     after do
#       OmniAuth.config.test_mode = false
#       OmniAuth.config.mock_auth[:publik] = nil
#       OmniAuth.config.camelizations.delete("publik")
#     end
#
#     context "when the user has confirmed the email in publik" do
#       it "creates a new User without sending confirmation instructions" do
#         click_on("Log in", match: :first)
#
#         click_on("Publik", match: :first)
#
#         expect(page).to have_content("Successfully")
#         expect_user_logged
#       end
#     end
#   end
# end
