# frozen_string_literal: true

# Between Rails 6.x and 7.0, the digest clqss change fron SHA1 to SHA256
# This is a workaround to keep the old key for decrypting the attributes
# see : https://guides.rubyonrails.org/v7.0/upgrading_ruby_on_rails.html#key-generator-digest-class-changing-to-use-sha256
# see : https://github.com/decidim/decidim/blob/6e5d8c03429e7c919b27c513d96dffe820ad43fd/decidim-core/config/initializers/new_framework_defaults_7_0.rb#L29
#
# TODO : Remove this when we have a procedure to update all the encrypted attributes
module AttributeEncryptorExtends
  extend ActiveSupport::Concern

  included do
    def self.cryptor
      @cryptor ||= begin
        key = ActiveSupport::KeyGenerator.new("attribute").generate_key(
          Rails.application.secrets.secret_key_base, ActiveSupport::MessageEncryptor.key_len
        )
        encryptor = ActiveSupport::MessageEncryptor.new(key)

        old_key = ActiveSupport::KeyGenerator.new(
          "attribute",
          hash_digest_class: OpenSSL::Digest::SHA1
        ).generate_key(
          Rails.application.secrets.secret_key_base,
          ActiveSupport::MessageEncryptor.key_len
        )

        encryptor.rotate old_key
        encryptor
      end
    end
  end
end

Decidim::AttributeEncryptor.include(AttributeEncryptorExtends)
