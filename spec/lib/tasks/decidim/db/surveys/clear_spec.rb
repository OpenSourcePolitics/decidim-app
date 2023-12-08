# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:db:surveys:clean", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "invokes the 'clear' method" do
    stub = Decidim::SurveysService.new
    allow(Decidim::SurveysService).to receive(:new).and_return stub
    allow(stub).to receive(:clear).and_return(true)

    task.execute

    expect(stub).to have_received(:clear)
  end
end
