# frozen_string_literal: true

# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.

class RandomStalling < Devise::FailureApp
  def respond
    sleep rand * 5
    super
  end

  protected

  def i18n_options(options)
    options[:locale] = session[:user_locale]
    super
  end
end

Devise.setup do |config|
  # ==> Configuration for :confirmable
  # A period that the user is allowed to access the website even without
  # confirming their account. For instance, if set to 2.days, the user will be
  # able to access the website for two days without confirming their account,
  # access will be blocked just in the third day. Default is 0.days, meaning
  # the user cannot access the website without confirming their account.
  config.allow_unconfirmed_access_for = ENV.fetch("DECIDIM_UNCONFIRMED_ACCESS", 0).to_i.days
end
