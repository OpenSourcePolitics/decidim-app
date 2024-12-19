# frozen_string_literal: true

module Decidim
  module Logging
    private

    def log!(msg, level = :warn)
      msg = "(#{self.class}) #{Time.current.strftime("%d-%m-%Y %H:%M")}> #{msg}"
      case level
      when :info
        Rails.logger.info msg
      else
        Rails.logger.warn msg
      end
    end
  end
end
