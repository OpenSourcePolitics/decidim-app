# frozen_string_literal: true

require "spec_helper"

describe "rake scaleway:storage:migrate_from_local", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "invokes the migrator" do
    expect(ActiveStorage::Migrator).to receive(:migrate!).with(:local, :scaleway).at_least(:once).and_return(true)

    task.execute
  end
end
