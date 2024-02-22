# Contributing to code

This document is a work in progress

## Unit tests

We use RSpec to run all our tests:

```sh
bundle exec rake test:run
# or
bundle exec rspec
```

System tests are run on a Chrome/Chromium browser. The chromedriver corresponding to your version is required and should be available in the `$PATH`.

To run tests without system tests:

```sh
bundle exec rails assets:precompile

# Then:
bundle exec rake "test:run[exclude, spec/system/**/*_spec.rb]"
# or
bundle exec rspec --tag ~type:system 
```

To replay failed tests, use the `--next-failure` flag.

### Code coverage

To generate code coverage, use the `SIMPLECOV=1` environment variable when starting tests.

## Linters

We use Rubocop to lint Ruby files:

```sh
bundle exec rubocop
```
