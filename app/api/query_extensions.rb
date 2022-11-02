# frozen_string_literal: true

module QueryExtensions
  def self.included(type)
    type.field :deployment, ::DeploymentType, "Decidim's framework properties.", null: true
  end

  def deployment
    OpenStruct.new
  end
end
