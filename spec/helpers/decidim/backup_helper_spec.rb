# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::BackupHelper do
  include Decidim::BackupHelper

  let(:hostname) { Socket.gethostname.encode("utf-8") }
  let(:dir_name) { "test project" }
  let(:branch) { "some_branch" }

  let!(:temp_dir) do
    dir = Dir.mktmpdir("decidim-tests-")
    FileUtils.cd dir do
      # Use another, known directory
      FileUtils.mkdir_p dir_name
      `cd "#{dir_name}" && git init && git checkout -b #{branch}}`
    end
    File.join(dir, dir_name)
  end

  after do
    FileUtils.rm_rf File.dirname(temp_dir)
  end

  describe "#generate_subfolder_name" do
    context "with an existing Git repository" do
      it "returns the right string" do
        expected = "#{hostname.parameterize}--#{dir_name.parameterize}--#{branch.parameterize}"

        FileUtils.cd temp_dir do
          expect(generate_subfolder_name).to eq expected
        end
      end
    end

    context "without a Git repository" do
      # it "raises an exception" do
      #   FileUtils.cd File.dirname(temp_dir) do
      #     expect do
      #       generate_subfolder_name
      #     end.to raise_error
      #   end
      # end

      it "returns an incomplete string" do
        expected = "#{hostname.parameterize}----"

        FileUtils.cd File.dirname(temp_dir) do
          expect(generate_subfolder_name).to eq expected
        end
      end
    end
  end
end
