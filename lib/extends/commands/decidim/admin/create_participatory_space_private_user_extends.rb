# frozen_string_literal: true

module CreateParticipatorySpacePrivateUserExtends
  # Executes the command. Broadcasts these events:
  #
  # - :ok when everything is valid.
  # - :invalid if the form wasn't valid and we couldn't proceed.
  #
  # Returns the Decidim::User object.
  def call
    return broadcast(:invalid) if form.invalid?

    ActiveRecord::Base.transaction do
      @user ||= existing_user || new_user
      create_private_user
    end

    # We add the user as a return value for logging purpose
    broadcast(:ok, @user)
  rescue ActiveRecord::RecordInvalid
    form.errors.add(:email, :taken)
    broadcast(:invalid)
  end
end

Decidim::Admin::CreateParticipatorySpacePrivateUser.class_eval do
  prepend(CreateParticipatorySpacePrivateUserExtends)
end
