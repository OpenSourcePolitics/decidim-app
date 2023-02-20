# frozen_string_literal: true

require "spec_helper"
require "decidim/assets_hash"

module Decidim
  describe AssetsHash do
    subject { described_class.new }

    # We need to stub the methods that call the filesystem to avoid
    # having to create the files in the filesystem.
    describe "#files_digest" do
      let(:files) { %w(app/packs/js/file0.js app/packs/js/file1.js) }

      before do
        allow(Dir).to receive(:glob).and_return(files)
        allow(File).to receive(:file?).and_return(true)
        allow(File).to receive(:read).and_return("content")
      end

      it "returns a assets hash manifest" do
        expect(subject.files_digest(["app/packs/**/*"])).to eq({
                                                                 "app/packs/js/file0.js" => "ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73",
                                                                 "app/packs/js/file1.js" => "ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73"
                                                               })
      end

      context "when there are multiples files in the same directory" do
        let(:files) { [["app/packs/js/file0.js", "app/packs/js/file1.js"], "app/packs/js/file2.js"] }

        it "digest the files" do
          expect(subject.files_digest(["app/packs/**/*"])).to eq({
                                                                   "app/packs/js/file0.js" => "ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73",
                                                                   "app/packs/js/file1.js" => "ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73",
                                                                   "app/packs/js/file2.js" => "ed7002b439e9ac845f22357d822bac1444730fbdb6016d3ec9432297b9ec9f73"
                                                                 })
        end
      end
    end

    describe "#run" do
      let(:content) { "content\ncontent\ncontent" }
      let(:content_digest) { Digest::SHA256.hexdigest(JSON.pretty_generate({ content: Digest::SHA256.hexdigest(content) })) }

      before do
        allow(subject).to receive(:files_digest).and_return({ content: Digest::SHA256.hexdigest(content) })
      end

      it "returns a hash" do
        expect(subject.run).to be_a(String)
        expect(subject.run).to eq(content_digest)
      end
    end
  end
end
