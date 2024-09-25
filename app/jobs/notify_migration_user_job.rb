# frozen_string_literal: true

class NotifyMigrationUserJob < ApplicationJob
  queue_as :block_user

  def perform(user)
    ::Decidim::NotifyMigrationUserMailer.notify(user).deliver_now
  end
end