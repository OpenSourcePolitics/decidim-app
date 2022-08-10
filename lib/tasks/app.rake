# frozen_string_literal: true

namespace :app do
  desc "Upgrade the base code of the Decidim-app"
  task upgrade: :environment do
    puts "----- Upgrading base code of Decidim-app ------"
    if ENV["DECIDIM_BRANCH"]
      decidim_version = ENV["DECIDIM_BRANCH"]
    else
      raise "You must provide env var 'DECIDIM_BRANCH' for using this rake task"
    end

    upgrader = Upgrader.new decidim_version

    upgrader.fetch_ruby_version!
    upgrader.fetch_node_version!
    # upgrader.update_rubocop!
    upgrader.rewrite_gemfile!
  end
end

class Upgrader
  attr_accessor :version

  def initialize(gh_branch, quiet = false)
    @version = gh_branch
    @quiet = false
    @repository_url = "https://raw.githubusercontent.com/decidim/decidim/#{@version}/"
  end

  def fetch_ruby_version!
    fetch_and_save! ".ruby-version"
  end

  def fetch_node_version!
    fetch_and_save! ".node-version"
  end

  def update_rubocop!
    puts "Fetching and saving file '.rubocop.yml'..." unless @quiet

    rubocop = YAML.load_file('.rubocop.yml')
    rubocop["inherit_from"] = "#{@repository_url}.rubocop.yml"

    File.write(".rubocop.yml", rubocop.to_yaml)
  end

  def rewrite_gemfile!
    puts "Preparing Gemfile..." unless @quiet
    in_block = false

    file_contents = File.readlines('Gemfile').map do |line|
      if line.include?("DECIDIM_VERSION =")
        line = "DECIDIM_VERSION = \"#{@version}\"\n"
      end

      if line.include?("## End")
        in_block = false
      end

      if in_block
        line = "# #{line}" unless line.start_with?("#")
      end

      if line.include?("## Block")
        in_block = true
      end

      line
    end

    File.write("Gemfile", file_contents.join)
    puts "Gemfile updated!" unless @quiet
    compare_gemfiles
  end

  private

  def compare_gemfiles
    puts "/!\ You must know compare manually the original Gemfile and the Decidim-app Gemfile"
    puts "Please update the dependencies versions according to the following Gemfile"
    sleep 3

    new = get("Gemfile")
    new.split("\n").each { |line| puts line }

    puts "Done ? (Type Enter)"
    $stdin.gets.to_s.strip
  end

  def fetch_and_save!(filename)
    puts "Fetching and saving file '#{filename}'..." unless @quiet

    content = get(filename)
    store!(filename, content)
  end

  def store!(filename, content)
    File.write(filename, content)
  end

  def get(file)
    curl("#{@repository_url}#{file}")
  end

  def curl(uri)
    response = Faraday.get(uri)
    response.body
  end
end
