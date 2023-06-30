require "yaml"

module DecidimApp
  module K8s
    class Manager
      def initialize(path)
        @configuration = Configuration.new(YAML.safe_load(path))
      end

      def self.install(path)
        new(path).install
      end

      def install
        raise "Invalid configuration: #{@configuration.errors}" unless @configuration.valid?
      end
    end
  end
end