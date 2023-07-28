# frozen_string_literal: true

module CreateRegistrationExtends
  def create_user
    @user = Decidim::User.create!(
      email: form.email,
      name: form.name,
      nickname: form.nickname,
      password: form.password,
      password_confirmation: form.password_confirmation,
      organization: form.current_organization,
      tos_agreement: form.tos_agreement,
      email_on_notification: true,
      accepted_tos_version: form.current_organization.tos_version,
      locale: form.current_locale
    )
  end
end

Decidim::CreateRegistration.class_eval do
  prepend(CreateRegistrationExtends)
end
