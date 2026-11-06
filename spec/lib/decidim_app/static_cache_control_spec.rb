# frozen_string_literal: true

require "spec_helper"
require "decidim_app/static_cache_control"

describe DecidimApp::StaticCacheControl do
  subject(:middleware) { described_class.new(app) }

  let(:status) { 200 }
  let(:app) { ->(_env) { [status, { "Last-Modified" => "Fri, 06 Nov 2026 00:00:00 GMT" }, ["body"]] } }
  let(:immutable) { "public, max-age=31536000, immutable" }

  def cache_control_for(path)
    _status, headers, _body = middleware.call(Rack::MockRequest.env_for(path))
    headers["Cache-Control"]
  end

  it "sets a long-lived header on JS packs" do
    expect(cache_control_for("/decidim-packs/js/decidim_core-0123456789abcdef.js")).to eq(immutable)
  end

  it "sets a long-lived header on pack media" do
    expect(cache_control_for("/decidim-packs/media/images/remixicon.symbol-0123456789abcdef.svg")).to eq(immutable)
  end

  it "does not touch the packs manifest" do
    expect(cache_control_for("/decidim-packs/manifest.json")).to be_nil
  end

  it "does not touch non-fingerprinted public files" do
    expect(cache_control_for("/robots.txt")).to be_nil
    expect(cache_control_for("/apple-touch-icon.png")).to be_nil
    expect(cache_control_for("/422.html")).to be_nil
  end

  it "does not touch application pages" do
    expect(cache_control_for("/processes")).to be_nil
  end

  context "when the file is not found" do
    let(:status) { 404 }

    it "does not set the header" do
      expect(cache_control_for("/decidim-packs/js/missing.js")).to be_nil
    end
  end

  context "when the file is not modified" do
    let(:status) { 304 }

    it "sets the header" do
      expect(cache_control_for("/decidim-packs/js/decidim_core-0123456789abcdef.js")).to eq(immutable)
    end
  end
end
