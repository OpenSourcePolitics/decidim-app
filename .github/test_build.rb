#!/usr/bin/env ruby
# frozen_string_literal: true

# create env file if not exists
system("touch .env") unless File.exist?(".env")

# start docker compose in background
system("docker-compose up -d")

# wait for the container to be ready by checking the logs
10.times do
  logs = `docker-compose logs app`
  break if logs.include?("Listening on http://0.0.0.0:3000")

  puts "Waiting for the container to be ready..."
  sleep 10
end

# curl localhost and expect a 301 redirect
# parse response code with curl
response_code = `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000`

# stop docker compose
system("docker-compose down")

if response_code == "301"
  puts "301 redirect found, success!"
  exit 0
else
  puts "Expected 301 redirect but got #{response_code}"
  exit 1
end
