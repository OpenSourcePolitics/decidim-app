# frozen_string_literal: true

require "aws-sdk-core"

return unless Rails.application.config.active_storage.service == :amazon_instance_profile

Aws.config.update(credentials: Aws::ECSCredentials.new)
