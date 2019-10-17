require "sidekiq/web"
Rails.application.routes.draw do

  authenticate :admin do
    mount Sidekiq::Web => '/sidekiq'
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  mount Decidim::Core::Engine => '/'
  # mount Decidim::Map::Engine => '/map'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
