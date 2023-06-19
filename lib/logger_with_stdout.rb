# frozen_string_literal: true

class LoggerWithStdout < Logger
  def initialize(*)
    super

    # rubocop:disable Lint/NestedMethodDefinition
    def @logdev.write(msg)
      super

      $stdout.puts(msg)
    end
    # rubocop:enable Lint/NestedMethodDefinition
  end
end
