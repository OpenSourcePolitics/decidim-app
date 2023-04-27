# frozen_string_literal: true

module EnvironmentVariablesHelper
  def with_modified_env(options = {}, &block)
    ClimateControl.modify(options, &block)
  end
end
