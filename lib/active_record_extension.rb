require 'active_support/concern'

module ActiveRecordExtension

  extend ActiveSupport::Concern

  included do
    connects_to database: { writing: :primary, reading: :primary_replica }
  end
end

# include the extension
ActiveRecord::Base.include ActiveRecordExtension
