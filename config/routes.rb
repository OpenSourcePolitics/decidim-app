# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  authenticate :admin do
    mount Sidekiq::Web => "/sidekiq"
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  mount Decidim::Core::Engine => "/"
  # mount Decidim::Map::Engine => '/map'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end

Decidim::Assemblies::AdminEngine.class_eval do
  routes do
    scope "/assemblies/:assembly_slug" do
      resources :components do
        resources :reminders, only: [:new, :create]
      end
    end
  end
end

Decidim::Conferences::AdminEngine.class_eval do
  routes do
    scope "/conferences/:conference_slug" do
      resources :components do
        resources :reminders, only: [:new, :create]
      end
    end
  end
end

Decidim::ParticipatoryProcesses::AdminEngine.class_eval do
  routes do
    scope "/participatory_processes/:participatory_process_slug" do
      resources :components do
        resources :reminders, only: [:new, :create]
      end
    end
  end
end
