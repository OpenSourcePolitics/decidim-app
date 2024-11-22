# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  authenticate :admin do
    mount Sidekiq::Web => "/sidekiq"
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || ENV.fetch("ENABLE_LETTER_OPENER", "0") == "1"

  mount Decidim::Core::Engine => "/"
end
