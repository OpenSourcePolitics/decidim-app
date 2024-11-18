# frozen_string_literal: true

namespace :override do
  desc "Find the original spec file to override"
  # Add FILE_PATH to the command line to find the original spec file
  # Example: rake override:find FILE_PATH=spec/controllers/registrations_controller_spec.rb
  task rspec: :environment do
    file_path = ENV.fetch("file", nil)

    src = Bundler.locked_gems.sources.select { |source| source.respond_to?(:ref) }.first
    path = src&.path&.to_s

    if path.nil?
      puts "No source path found for #{file_path}"
      puts "Note: Ensure the gem is installed from Github"
      return
    end

    Dir.glob("#{path}/**/#{file_path}").each do |file|
      puts "Found file in path: #{file}"

      path = File.dirname(file_path)
      FileUtils.mkdir_p(path)
      File.open(file_path, "w") do |f|
        content = File.read(file)
        f.write(content)
      end

      puts "File created in path: #{file_path}"
    end
  end
end
