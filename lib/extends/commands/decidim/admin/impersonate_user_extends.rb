# frozen_string_literal: true

module ImpersonateUserExtends
  # Executes the command. Broadcasts these events:
  #
  # - :ok when everything is valid.
  # - :invalid if the impersonation is not valid.
  #
  # Returns the Decidim::User object.
  def call
    return broadcast(:invalid) unless form.valid?

    transaction do
      user.save! unless user.persisted?
      create_authorization
      # No need to start an impersonation session
      # create_impersonation_log
    end

    # No need to stop an impersonation session either
    # enqueue_expire_job

    # We add the user as a return value for logging purpose
    broadcast(:ok, user)
  end
end

Decidim::Admin::ImpersonateUser.class_eval do
  prepend(ImpersonateUserExtends)
end
