# frozen_string_literal: true

module DecidimApp
  module K8s
    module SecondaryHostsChecker
      def self.valid_secondary_hosts(host:, secondary_hosts:)
        secondary_hosts.select do |secondary_host|
          valid_secondary_host?(host, secondary_host)
        end
      end

      def self.valid_secondary_host?(host, secondary_host)
        return true if host == secondary_host

        host == get_redirection_target(secondary_host)
      end

      def self.get_redirection_target(host, limit = 3)
        raise "Secondary host #{host} is not valid because of too many redirections" if limit.zero?

        req = Net::HTTP::Get.new("/")
        response = Net::HTTP.start(host, 443, use_ssl: true) { |http| http.request(req) }

        case response
        when Net::HTTPSuccess
          host
        when Net::HTTPRedirection
          get_redirection_target(response["location"], limit - 1)
        end
      rescue SocketError, Errno::ECONNREFUSED
        nil
      end
    end
  end
end
