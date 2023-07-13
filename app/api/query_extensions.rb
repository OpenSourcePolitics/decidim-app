# frozen_string_literal: true

module QueryExtensions
  def self.included(type)
    type.field :deployment, ::DeploymentType, "Deployment's properties.", null: true
  end

  def deployment
    Struct.new
  end
end
