# frozen_string_literal: true

class ApplicationMailer < Decidim::ApplicationMailer
  default from: "from@example.com"
  layout "mailer"
end
