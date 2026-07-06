# frozen_string_literal: true

module CreateOmniauthRegistrationExtends
  def call
    verify_oauth_signature!

    begin
      if existing_identity
        @identity = existing_identity
        @user = @identity.user
        verify_user_confirmed(@user)
        trigger_omniauth_registration

        return broadcast(:ok, @user)
      end

      prefill_euf_fields_from_existing_user

      return broadcast(:invalid) if form.invalid?

      transaction do
        create_or_find_user
        @identity = create_identity
      end
      send_email_to_statutory_representative
      manage_user_confirmation
      trigger_omniauth_registration

      broadcast(:ok, @user)
    rescue ActiveRecord::RecordInvalid => e
      broadcast(:error, e.record)
    end
  end

  def manage_user_confirmation
    # send welcome notification and email
    @user.after_confirmation if verified_email
  end

  private

  def prefill_euf_fields_from_existing_user
    existing_user = Decidim::User.find_by(
      email: form.email,
      organization: form.current_organization
    )
    return unless existing_user

    existing_data = existing_user.extended_data.presence || {}
    %w(phone_number country postal_code date_of_birth gender location underage).each do |field|
      next unless form.respond_to?(:"#{field}=")
      next if existing_data[field].blank?

      form.public_send(:"#{field}=", existing_data[field])
    end
  end
end

Decidim::CreateOmniauthRegistration.class_eval do
  prepend(CreateOmniauthRegistrationExtends)
end
