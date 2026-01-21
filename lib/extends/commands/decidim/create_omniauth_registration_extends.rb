# frozen_string_literal: true

module CreateOmniauthRegistrationExtends
  def call
    verify_oauth_signature!

    begin
      if (@identity = existing_identity)
        @user = existing_identity.user
        verify_user_confirmed(@user)

        trigger_omniauth_event("decidim.user.omniauth_login")
        return broadcast(:ok, @user)
      end
      return broadcast(:invalid) if form.invalid?

      transaction do
        create_or_find_user
        @identity = create_identity
      end
      manage_user_confirmation
      trigger_omniauth_event

      broadcast(:ok, @user)
    rescue NeedTosAcceptance
      broadcast(:add_tos_errors, @user)
    rescue ActiveRecord::RecordInvalid => e
      broadcast(:error, e.record)
    end
  end

  def manage_user_confirmation
    # send welcome notification and email
    @user.after_confirmation
  end
end

Decidim::CreateOmniauthRegistration.class_eval do
  prepend(CreateOmniauthRegistrationExtends)
end
