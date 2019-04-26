if Rails.application.secrets.dig(:omniauth, :publik).present? && Rails.application.secrets.dig(:omniauth, :publik, :enabled)
  Devise.setup do |config|
    config.omniauth :publik,
                    Rails.application.secrets.dig(:omniauth, :publik, :client_id),
                    Rails.application.secrets.dig(:omniauth, :publik, :client_secret),
                    Rails.application.secrets.dig(:omniauth, :publik, :site_url),
                    scope: :public
  end

  Decidim::User.omniauth_providers << :publik
end
