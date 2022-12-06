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
        allow(subject).to receive(:exec).with("bundle exec rspec controllers/example3.rb")
      end

      it "executes the rspec command on the correct files" do
        expect(subject.run).to eq(nil)
      end
    end

    describe "#all_files" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
      end

      it "returns the correct files" do
        expect(subject.all_files).to eq([%w(system/example1.rb lib/example2.rb), %w(controllers/example3.rb), %w(lib/example4.rb), %w(system/example5.rb)])
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
