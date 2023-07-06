# frozen_string_literal: true

require "spec_helper"
require "decidim_app/k8s/secondary_hosts_checker"

describe DecidimApp::K8s::SecondaryHostsChecker do
  subject { described_class }

  let(:host) { "example.org" }
  let(:secondary_hosts) { ["www.example.org"] }
  let(:target) { "https://#{secondary_hosts.first}" }
  let(:response_code) { 301 }
  let(:response_headers) { { "location" => host } }

  before do
    # Our system checks for redirection then returns the host
    # We need to make two requests minimum to get the redirection target because redirection can be chained
    # First request to get the redirection
    stub_request(:get, target).with(headers: {
                                      "Accept" => "*/*",
                                      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                                      "User-Agent" => "Ruby"
                                    }).to_return(status: response_code, body: "", headers: response_headers)

    # Second request to get the host
    stub_request(:get, "https://#{host}/").with(headers: {
                                                  "Accept" => "*/*",
                                                  "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                                                  "User-Agent" => "Ruby"
                                                }).to_return(status: 200, body: "", headers: {})
  end

  describe ".get_redirection_target" do
    it "returns the redirection target" do
      expect(subject.get_redirection_target(secondary_hosts.first)).to eq(host)
    end

    context "when the host is not a redirection" do
      let(:target) { "https://#{host}" }
      let(:response_headers) { {} }
      let(:response_code) { 200 }

      it "returns the host if it is valid" do
        expect(subject.get_redirection_target(host)).to eq(host)
      end
    end

    context "when the host is not valid" do
      let(:target) { "https://nothing.org" }
      let(:response_code) { 404 }

      it "returns nil" do
        expect(subject.get_redirection_target("nothing.org")).to eq(nil)
      end
    end

    context "when the host is not valid because of too many redirections" do
      let(:target) { "https://redirection.org" }
      let(:response_headers) { { "location" => "another_redirection.org" } }

      it "raises an exception" do
        expect { subject.get_redirection_target("redirection.org", 1) }.to raise_error(RuntimeError, "Secondary host another_redirection.org is not valid because of too many redirections")
      end
    end

    context "when the host is not valid because of a socket error" do
      [Errno::ECONNREFUSED, SocketError].each do |error|
        it "returns nil" do
          stub_request(:get, target).to_raise(error)
          expect(subject.get_redirection_target(secondary_hosts.first)).to eq(nil)
        end
      end
    end
  end

  describe ".valid_secondary_host?" do
    it "returns true if the host is valid" do
      expect(subject.valid_secondary_host?(host, secondary_hosts.first)).to eq(true)
    end

    context "when host is not valid" do
      let(:target) { "https://nothing.org" }
      let(:response_code) { 404 }

      it "returns false" do
        expect(subject.valid_secondary_host?(host, "nothing.org")).to eq(false)
      end
    end
  end

  describe ".valid_secondary_hosts" do
    it "returns the valid secondary hosts" do
      expect(subject.valid_secondary_hosts(host: host, secondary_hosts: secondary_hosts)).to eq(secondary_hosts)
    end

    context "when there are invalid secondary hosts" do
      let(:target) { "https://nothing.org" }
      let(:response_code) { 404 }

      it "returns an empty array" do
        expect(subject.valid_secondary_hosts(host: host, secondary_hosts: ["nothing.org"])).to eq([])
      end
    end
  end
end
