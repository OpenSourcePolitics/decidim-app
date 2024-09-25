# frozen_string_literal: true

module Decidim
  class NotifyMigrationUserMailer < ApplicationMailer
    def notify(user)
      with_user(user) do
        @user = user
        @organization = user.organization
        subject = "La plateforme de participation citoyenne de Bordeaux Métropole fait peau neuve !"

        mail(to: user.email, subject: subject)
      end
    end
  end
end
