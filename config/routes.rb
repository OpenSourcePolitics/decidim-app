require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  authenticate :admin do
    mount Sidekiq::Web => "/sidekiq"
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  mount Decidim::Core::Engine => '/'
end
