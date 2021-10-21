# frozen_string_literal: true

module Decidim
  module BackupHelper
    def generate_subfolder_name
      [
        `hostname`,
        File.basename(`git rev-parse --show-toplevel`),
        `git branch --show-current`
      ].map(&:parameterize).join("--")
    end
  end
end
