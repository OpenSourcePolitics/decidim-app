# frozen_string_literal: true

module CreateOmniauthRegistrationExtends

  # Executes the command. Broadcasts these events:
  #
  # - :ok when everything is valid.
  # - :invalid if the form wasn't valid and we couldn't proceed.
  #
  # Returns nothing.
  def call
    Rails.logger.debug("Decidim::CreateOmniauthRegistrationExtends.call")
    verify_oauth_signature!

    begin
      if existing_identity
        @identity = existing_identity
        @user = @identity.user
        verify_user_confirmed(@user)
        trigger_omniauth_registration

        return broadcast(:ok, @user)
      end
      return broadcast(:invalid) if form.invalid?

      transaction do
        create_or_find_user
        @identity = create_identity
      end
      trigger_omniauth_registration

      broadcast(:ok, @user)
    rescue ActiveRecord::RecordInvalid => e
      broadcast(:error, e.record)
    end
  end
end

Decidim::CreateOmniauthRegistration.class_eval do
  prepend(CreateOmniauthRegistrationExtends)
end
