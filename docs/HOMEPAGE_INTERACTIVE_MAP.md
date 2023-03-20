# Module Homepage Interactive Map

[This module](https://github.com/openSourcePolitics/decidim-module-homepage_interactive_map) displays an interactive map on homepage.

## Getting started

1. Install module
```
bundle install
```
2. Install webpacker dependencies

```
bundle exec rake decidim_homepage_interactive_map:webpacker:install
```

3. Install `proj` dependencies

**OSX using Homebrew**
```bash
brew install proj
bundle config set build.rgeo-proj4 --with-proj-dir="/opt/homebrew/"
bundle pristine rgeo-proj4
bundle install
```

**Ubuntu**
```bash
sudo apt update && sudo apt install libproj-dev proj-bin -y
PROJ_DIR=$(which proj) bundle config set build.rgeo-proj4 --with-proj-dir="${PROJ_DIR%proj}"
bundle pristine rgeo-proj4
bundle install
```

4. Repair data if already defined

```bash
bundle exec rake decidim_homepage_interactive_map:check_for_repair
bundle exec rake decidim_homepage_interactive_map:repair_data
```

🚀 Interactive map should be completely available in your Decidim-app ! 