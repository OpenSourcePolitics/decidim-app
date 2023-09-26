# frozen_string_literal: true

module DecidimApp
  module K8s
    class Command < Decidim::Command
      attr_writer :status_registry

      def self.register_topic(topic)
        @topic = topic
      end

      def logger
        @logger ||= DecidimApp::K8s::Manager.logger
      end

      def topic
        raise "Topic not registered" unless self.class.instance_variable_defined?(:@topic)

        self.class.instance_variable_get(:@topic)
      end

      def status_registry
        @status_registry ||= {}
      end

      def any_status_invalid?
        status_registry[topic].any? { |_action, status| status[:status] != :ok }
      end

      def register_status(action, status, messages = [])
        self.status_registry = status_registry.deep_merge(topic => { action => { status: status, messages: messages } })
      end

      def broadcast_status(model)
        return broadcast(:invalid, status_registry, nil) if any_status_invalid?

        broadcast(:ok, status_registry, model.reload)
      end

      def errors_for(form)
        form.tap(&:valid?).errors.messages.transform_values(&:uniq)
      end
    end
  end
end
