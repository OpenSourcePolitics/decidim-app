#!/bin/bash
set -e

bundle exec rake db:create decidim_app:k8s:install
bundle exec rails server -b "ssl://0.0.0.0:3000?key=/app/certificate-https-local/key.pem&cert=/app/certificate-https-local/cert.pem"
