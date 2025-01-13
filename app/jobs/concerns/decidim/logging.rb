# frozen_string_literal: true

module Decidim
  module Logging
    private

    def log!(msg, level = :warn)
      msg = "(#{self.class})> #{msg}"

      case level
      when :info
        Rails.logger.info msg
        stdout_logger.info msg unless Rails.env.test?
      else
        Rails.logger.warn msg
        stdout_logger.warn msg unless Rails.env.test?
      end
    end

    def stdout_logger
      @stdout_logger ||= Logger.new($stdout)
    end
  end
end
