# frozen_string_literal: true

require "spec_helper"
require "decidim/rspec_runner"

module Decidim
  describe RSpecRunner do
    subject { described_class.new(pattern, slice) }

    let(:pattern) { "spec/**/*_spec.rb" }
    let(:slice) { "1-4" }
    let(:files) do
      %w(example1.rb example2.rb example3.rb example4.rb example5.rb)
    end

    describe "#run" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
        allow(subject).to receive(:exec).with("bundle exec rspec example3.rb")
      end

      it "executes the rspec command on the correct files" do
        expect(subject.run).to eq(nil)
      end
    end

    describe "#files" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
      end

      it "returns the correct files" do
        expect(subject.all_files).to eq([%w(example1.rb example2.rb), %w(example3.rb), %w(example4.rb), %w(example5.rb)])
      end
    end

    describe "#sliced_files" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
      end

      it "returns the correct files" do
        expect(subject.sliced_files).to eq(%w(example3.rb))
      end
    end
  end
end
