# frozen_string_literal: true

module SkipIfUndefinedHelper
  # Skips a test if a given class is undefined (i.e. : from another gem)
  def skip_if_undefined(klass, gem)
    skip "'#{gem}' gem is not present" unless klass.safe_constantize
  end
end
