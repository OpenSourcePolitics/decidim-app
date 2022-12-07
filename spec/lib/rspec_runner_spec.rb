# frozen_string_literal: true

require "spec_helper"
require "decidim/rspec_runner"

module Decidim
  describe RSpecRunner do
    subject { described_class.new(pattern, mask, slice) }

    let(:pattern) { "include" }
    let(:mask) { "spec/**/*_spec.rb" }
    let(:slice) { "1-4" }
    let(:files) do
      %w(system/example1.rb lib/example2.rb controllers/example3.rb lib/example4.rb system/example5.rb)
    end

    describe "#run" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
        allow(subject).to receive(:exec).with("RAILS_ENV=test bundle exec rake parallel:spec controllers/example3.rb")
      end

      it "executes the rspec command on the correct files" do
        expect(subject.run).to eq(nil)
      end
    end

    describe "#defaults_files" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
      end

      it "returns the default files" do
        expect(subject.default_files).to eq(files)
      end
    end

    describe "#all_files" do
      context "when using include pattern" do
        before do
          allow(Dir).to receive(:glob).and_return(files)
        end

        it "returns the correct files" do
          expect(subject.all_files).to eq(%w(system/example1.rb lib/example2.rb controllers/example3.rb lib/example4.rb system/example5.rb))
        end
      end

      context "when using exclude pattern" do
        let(:pattern) { "exclude" }
        let(:files) do
          %w(system/example1.rb lib/example2.rb controllers/example3.rb lib/example4.rb system/example5.rb)
        end
        let(:filtered_files) do
          %w(system/example1.rb system/example5.rb)
        end

        before do
          # Default files returns all spec files
          allow(subject).to receive(:default_files).and_return(files)

          # Filtered files returns the ones that match the mask
          allow(Dir).to receive(:glob).and_return(filtered_files)
        end

        it "returns the correct files" do
          expect(subject.all_files).to eq(%w(lib/example2.rb controllers/example3.rb lib/example4.rb))
        end
      end
    end

    describe "#sliced_files" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
      end

      it "returns the correct files" do
        expect(subject.sliced_files).to eq(%w(controllers/example3.rb))
      end
    end
  end
end
