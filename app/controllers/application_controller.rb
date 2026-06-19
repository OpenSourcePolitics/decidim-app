# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :check_euf_completion, if: :current_user
end
