require 'spec_helper'

describe DevelopmentApp::Application, "configuration" do
  subject(:application) { described_class.config }

  describe 'config' do
    it 'set action_dispatch default headers' do
      expect(application.action_dispatch.default_headers).to include({
                                                                       "X-Frame-Options" => "SAMEORIGIN",
                                                                       "X-XSS-Protection" => "1; mode=block",
                                                                       "X-Content-Type-Options" => "nosniff"
                                                                     })
    end
  end
end
