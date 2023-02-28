# frozen_string_literal: true

if ENV["SIMPLECOV"]
  test_type = ENV.fetch("TEST_ENV_TYPE", "tests")
  test_slice = ENV.fetch("TEST_ENV_SLICE", "0-1")
  test_env = ENV.fetch("TEST_ENV_NUMBER", "0")

  SimpleCov.start do
    # We ignore some of the files because they are never tested
    add_filter "/config/"
    add_filter "/db/"
    add_filter "/vendor/"
    add_filter "/packages/"
    add_filter "/spec/"
    add_filter "/test/"
  end

  SimpleCov.merge_timeout 1800
  SimpleCov.coverage_dir "coverage/#{test_type}/#{test_slice}/#{test_env}/"

  if ENV["CI"]
    require "simplecov-cobertura"
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  end
end
