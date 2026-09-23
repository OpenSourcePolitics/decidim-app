# frozen_string_literal: true

class DummyLongJob < ApplicationJob
  def perform(duration: 60.seconds, step: 5.seconds)
    elapsed = 0
    total_steps = (duration / step).to_i
    Rails.logger.info "Starting DummyLongJob for #{duration} seconds with #{total_steps} steps of #{step} seconds each."
    step_index = 1
    while elapsed < duration
      Rails.logger.info "DummyLongJob progress: Step #{step_index}/#{total_steps} (#{elapsed}/#{duration} seconds)"
      sleep(step)
      elapsed += step.seconds
      step_index += 1
    end
  end
end
