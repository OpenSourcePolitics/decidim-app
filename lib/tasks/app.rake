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

  private

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
    # response = Net::HTTP.get_response(uri)
    # response.body if response.is_a?(Net::HTTPOK) && response.respond_to?(:body)
  end
end
