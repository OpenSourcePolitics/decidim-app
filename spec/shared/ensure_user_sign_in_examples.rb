# frozen_string_literal: true

shared_examples "ensure user sign in" do
  it "redirects user to the login page" do
    expect(page).to have_current_path(decidim.new_user_session_path)
    within_flash_messages do
      expect(page).to have_content "You need to login first."
    end
  end
end
