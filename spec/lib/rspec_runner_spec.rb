# frozen_string_literal: true

require "spec_helper"
require "decidim/rspec_runner"

module Decidim
  describe RSpecRunner do
    subject { described_class.new(pattern, mask, slice) }

    let(:pattern) { "include" }
    let(:mask) { "spec/**/*_spec.rb" }
    let(:slice) { "0-4" }
    let(:files) do
      %w(system/example1_spec.rb lib/example2_spec.rb controllers/example3_spec.rb lib/example4_spec.rb system/example5_spec.rb)
    end

    describe "#run" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
        allow(subject).to receive(:exec).with("RAILS_ENV=test TEST_ENV_SLICE=0 TEST_ENV_TYPE=example1-example2 bundle exec rake parallel:spec['system/example1_spec.rb|lib/example2_spec.rb']")
      end

      it "executes the rspec command on the correct files" do
        expect(subject.run).to be_nil
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
          expect(subject.all_files).to eq(%w(system/example1_spec.rb lib/example2_spec.rb controllers/example3_spec.rb lib/example4_spec.rb system/example5_spec.rb))
        end
      end

      context "when using exclude pattern" do
        let(:pattern) { "exclude" }
        let(:files) do
          %w(system/example1_spec.rb lib/example2_spec.rb controllers/example3_spec.rb lib/example4_spec.rb system/example5_spec.rb)
        end
        let(:filtered_files) do
          %w(system/example1_spec.rb system/example5_spec.rb)
        end

        before do
          # Default files returns all spec files
          allow(subject).to receive(:default_files).and_return(files)

          # Filtered files returns the ones that match the mask
          allow(Dir).to receive(:glob).and_return(filtered_files)
        end

        it "returns the correct files" do
          expect(subject.all_files).to eq(%w(lib/example2_spec.rb controllers/example3_spec.rb lib/example4_spec.rb))
        end
      end
    end

    describe "#for" do
      context "with missing arguments" do
        it "fails without pattern" do
          expect do
            described_class.for nil, mask, slice
          end.to raise_error("Missing pattern")
        end

        it "fails without mask" do
          expect do
            described_class.for pattern, nil, slice
          end.to raise_error("Missing mask")
        end

        it "fails without slice" do
          expect do
            described_class.for pattern, mask, nil
          end.to raise_error("Missing slice")
        end
      end

      context "with all the arguments" do
        # This is tightly coupled with the implementation
        it "runs the suite" do
          allow(described_class).to receive(:new).and_return subject
          allow(subject).to receive(:run).and_return "__success__"

          expect(described_class.for(pattern, mask, slice)).to eq "__success__"
        end
      end
    end

    describe "#sliced_files" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
      end

      it "returns the correct files" do
        expect(subject.sliced_files).to eq(%w(system/example1_spec.rb lib/example2_spec.rb))
      end
    end

    describe "#sliced_files_groups" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
      end

      it "returns the correct files" do
        expect(subject.sliced_files_groups).to eq("example1-example2")
      end
    end

    describe "#environnement_variables" do
      before do
        allow(Dir).to receive(:glob).and_return(files)
      end

      it "returns the correct env" do
        expect(subject.environment_variables).to eq("RAILS_ENV=test TEST_ENV_SLICE=0 TEST_ENV_TYPE=example1-example2")
      end
    end
  end
end
