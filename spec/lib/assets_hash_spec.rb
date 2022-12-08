# frozen_string_literal: true

require "spec_helper"
require "decidim/assets_hash"

module Decidim
  describe AssetsHash do
    subject { described_class.new }

    # We need to stub the methods that call the filesystem to avoid
    # having to create the files in the filesystem.
    describe "#files_cat" do
      let(:files) { ["app/packs/js/file0.js", "app/packs/js/file1.js"] }

      before do
        allow(Dir).to receive(:glob).and_return(files)
        allow(File).to receive(:file?).and_return(true)
        allow(File).to receive(:read).and_return("content")
      end

      it "concatenates the files" do
        expect(subject.send(:files_cat, "app/packs/**/*")).to eq("content\ncontent")
      end

      context "when there are multiples files in the same directory" do
        let(:files) { [%w(app/packs/js/file0.js app/packs/js/file1.js), "app/packs/js/file2.js"] }

        it "concatenates the files" do
          expect(subject.send(:files_cat, "app/packs/**/*")).to eq("content\ncontent\ncontent")
        end
      end
    end

    describe "#run" do
      let(:content) { "content\ncontent\ncontent" }
      let(:content_digest) { Digest::SHA256.hexdigest(Digest::SHA256.hexdigest(content) * 2) }

      before do
        allow(subject).to receive(:files_cat).and_return(content)
      end

      it "returns a hash" do
        expect(subject.run).to be_a(String)
        expect(subject.run).to eq(content_digest)
      end
    end
  end
end
