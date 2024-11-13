# frozen_string_literal: true

# A URL where to obtain the translations for the FormBuilder component
# you can a custom place if you are worried about the CDN geolocation
# Download them from https://github.com/kevinchappell/formBuilder-languages

# For instance, copy them to your /public/fb_locales/ directory and set the path here:
Decidim::DecidimAwesome.configure do |config|
  config.form_builder_langs_location = "https://decidim.storage.opensourcepolitics.eu/osp-cdn/form_builder/1.1.0/"
end
