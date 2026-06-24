# frozen_string_literal: true

require "spec_helper"

describe "EUF Force Completion" do
  let(:organization) do
    create(:organization, extra_user_fields: {
             "enabled" => true,
             "phone_number" => { "enabled" => true, "required" => true }
           })
  end
  let(:password) { "dqCFgjfDbC7dPbrv" }
  let(:user) { create(:user, :confirmed, password:, organization:, extended_data: {}) }
  let!(:assembly) { create(:assembly, :published, organization:) }

  before do
    switch_to_host(organization.host)
    allow(Rails.application.secrets).to receive(:dig).and_call_original
    allow(Rails.application.secrets).to receive(:dig)
      .with(:decidim, :extra_user_fields, :force_euf_completion)
      .and_return(true)
  end

  context "when FORCE_EUF_COMPLETION is enabled and phone_number is missing" do
    before { login_as user, scope: :user }

    it "intercepts navigation and redirects to account" do
      visit decidim_assemblies.assemblies_path
      expect(page).to have_current_path(%r{/account})
      expect(page).to have_content(I18n.t("decidim.extra_user_fields.force_euf_completion.alert"))
    end

    it "does not intercept /account itself" do
      visit decidim.account_path
      expect(page).to have_current_path(decidim.account_path, ignore_query: true)
      expect(page).to have_css("form.edit_user")
    end

    it "does not intercept /users/sign_out" do
      visit decidim.destroy_user_session_path
      expect(page).to have_no_content(I18n.t("decidim.extra_user_fields.force_euf_completion.alert"))
    end

    context "when completing the profile from a normal navigation interception" do
      it "redirects back to the original destination after saving" do
        visit decidim_assemblies.assemblies_path
        expect(page).to have_current_path(%r{/account})

        within "form.edit_user" do
          fill_in "Phone Number", with: "+33612345678", match: :first
          find("*[type=submit]").click
        end

        within_flash_messages do
          expect(page).to have_content("successfully")
        end

        expect(page).to have_current_path(decidim_assemblies.assemblies_path, ignore_query: true)
      end
    end

    context "when the user is an admin" do
      let(:user) { create(:user, :confirmed, :admin, password:, organization:, extended_data: {}) }

      it "does not intercept navigation" do
        visit decidim_assemblies.assemblies_path
        expect(page).to have_current_path(decidim_assemblies.assemblies_path, ignore_query: true)
        expect(page).to have_no_content(I18n.t("decidim.extra_user_fields.force_euf_completion.alert"))
      end
    end
  end

  context "when FORCE_EUF_COMPLETION is disabled" do
    before do
      allow(Rails.application.secrets).to receive(:dig)
        .with(:decidim, :extra_user_fields, :force_euf_completion)
        .and_return(false)
      login_as user, scope: :user
    end

    it "does not intercept navigation" do
      visit decidim_assemblies.assemblies_path
      expect(page).to have_current_path(decidim_assemblies.assemblies_path, ignore_query: true)
      expect(page).to have_no_content(I18n.t("decidim.extra_user_fields.force_euf_completion.alert"))
    end
  end

  context "when phone_number is already filled" do
    let(:user) do
      create(:user, :confirmed, password:, organization:,
                                extended_data: { "phone_number" => "+33612345678" })
    end

    before { login_as user, scope: :user }

    it "does not intercept navigation" do
      visit decidim_assemblies.assemblies_path
      expect(page).to have_current_path(decidim_assemblies.assemblies_path, ignore_query: true)
      expect(page).to have_no_content(I18n.t("decidim.extra_user_fields.force_euf_completion.alert"))
    end
  end

  context "when user is invited to a private assembly" do
    let(:private_assembly) { create(:assembly, :published, :private, organization:) }
    let(:invited_user) do
      Decidim::User.invite!(
        { email: "invited@example.com", name: "Invited User", organization: },
        nil,
        { extended_data: {} }
      )
    end

    before do
      create(:participatory_space_private_user, user: invited_user, privatable_to: private_assembly)
    end

    it "redirects to the assembly after completing the profile" do
      visit decidim.accept_user_invitation_path(
        invitation_token: invited_user.raw_invitation_token
      )

      within "#invitation_edit_user" do
        fill_in "user[nickname]", with: "invited_user"
        fill_in "user[password]", with: password, match: :first
        check "user[tos_agreement]"
        find("*[type=submit]").click
      end

      expect(page).to have_current_path(%r{/account})
      expect(page).to have_content(I18n.t("decidim.extra_user_fields.force_euf_completion.alert"))

      within "form.edit_user" do
        fill_in "Phone Number", with: "+33612345678", match: :first
        find("*[type=submit]").click
      end

      within_flash_messages do
        expect(page).to have_content("successfully")
      end

      expect(page).to have_current_path(
        decidim_assemblies.assembly_path(private_assembly.slug),
        ignore_query: true
      )
    end
  end
end
