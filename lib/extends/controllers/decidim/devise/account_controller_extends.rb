# frozen_string_literal: true

module AccountControllerExtends
  def destroy
    enforce_permission_to :delete, :user, current_user: current_user
    @form = form(Decidim::DeleteAccountForm).from_params(params)

    Decidim::DestroyAccount.call(current_user, @form) do
      on(:ok) do
        sign_out(current_user)
        destroy_france_connect_session(session["omniauth.france_connect.end_session_uri"]) if active_france_connect_session?
        flash[:notice] = t("account.destroy.success", scope: "decidim")
      end

      on(:invalid) do
        flash[:alert] = t("account.destroy.error", scope: "decidim")
        redirect_to decidim.root_path
      end
    end
  end

  private

  def destroy_france_connect_session(fc_logout_path)
    session.delete("omniauth.france_connect.end_session_uri")

    redirect_to fc_logout_path
  end

  def active_france_connect_session?
    current_organization.enabled_omniauth_providers.include?(:france_connect) && session["omniauth.france_connect.end_session_uri"].present?
  end
end

Decidim::AccountController.class_eval do
  prepend(AccountControllerExtends)
end
