# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  if Decidim::Env.new("PUMA_HEALTH_CHECK_ENABLED", false).to_boolean_string == "true"
    port = Decidim::Env.new("PUMA_HEALTH_CHECK_PORT", 3124).to_i
    get "/stats", to: redirect { |_params, request| "http://#{request.host}:#{port}/stats?#{request.params.to_query}" }
  end

  authenticate :admin do
    mount Sidekiq::Web => "/sidekiq"
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || ENV.fetch("ENABLE_LETTER_OPENER", "0") == "1"

  devise_scope :user do
    get "users/sign_out",
        to: "decidim/devise/sessions#destroy"
  end

  mount Decidim::Core::Engine => "/"
end
