# Decidim app by OSP
[![codecov](https://codecov.io/gh/OpenSourcePolitics/decidim-app/branch/master/graph/badge.svg?token=VDQ3ORQLN6)](https://codecov.io/gh/OpenSourcePolitics/decidim-app)
[![Maintainability](https://api.codeclimate.com/v1/badges/f5abcda931760d6ee65d/maintainability)](https://codeclimate.com/github/OpenSourcePolitics/decidim-app/maintainability)
![Tests](https://github.com/OpenSourcePolitics/decidim-app/actions/workflows/deploy_production.yml/badge.svg?branch=master)
![Tests](https://github.com/OpenSourcePolitics/decidim-app/actions/workflows/tests.yml/badge.svg?branch=master)

## Decidim
![](./docs/decidim-logo-claim.svg)

[Decidim](https://github.com/decidim/decidim) is a digital platform for citizen participation. Related documentation can be found [here](https://docs.decidim.org)

## [Open Source Politics](https://opensourcepolitics.eu/) 
![Open Source Politics](./docs/open-source-politics.svg)

This repository contains the code of the **decidim-app** implemented for our customers.

It consists of the main application with modules developed by the community that we often use.

It includes **official modules** supported by the community and **community-based modules** developed by us our [our partners](https://github.com/decidim-ice)

### List of our modules

You can find below an exhaustive list of modules with their repository links and latest version available :

Here's the revised and improved formatting of the table:

| Decidim Module                                                                                                          | Version | Brief Description                                                                                                                                                             |
|-------------------------------------------------------------------------------------------------------------------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| decidim-core                                                                                                            | v0.27.4 | Core functionality for the Decidim platform.                                                                                                                                  |
| decidim-conferences                                                                                                     | v0.27.4 | Module for managing conferences and events.                                                                                                                                   |
| decidim-initiatives                                                                                                     | v0.27.4 | Module for managing citizen initiatives.                                                                                                                                      |
| decidim-templates                                                                                                       | v0.27.4 | Module for using templates within the Decidim platform.                                                                                                                       |
| [decidim-cache_cleaner](https://github.com/OpenSourcePolitics/decidim-module-cache_cleaner)                             | ✅       | Allows admins to clear the application cache in the back-office.                                                                                                              |
| [decidim-decidim_awesome](https://github.com/decidim-ice/decidim-module-decidim_awesome)                                | ✅       | An awesome module that includes: adding extra fields for proposals creation, fullscreen iframe component, image in rich text editor, custom redirections, etc.               |
| [decidim-friendly_signup](https://github.com/OpenSourcePolitics/decidim-module-friendly_signup)                         | ✅       | Drastically simplifies the user registration process by removing some fields.                                                                                                 |
| [decidim-homepage_interactive_map](https://github.com/OpenSourcePolitics/decidim-module-homepage_interactive_map)       | ✅       | Adds an interactive map content block on the homepage to display a map of assemblies for geo-located participation.                                                          |
| [decidim-phone_authorization_handler](https://github.com/OpenSourcePolitics/decidim-module-phone_authorization_handler) | ✅       | Gathers phone numbers on specific participant actions.                                                                                                                        |
| [decidim-spam_detection](https://github.com/OpenSourcePolitics/decidim-spam_detection)                                  | ✅       | Adds a spam detection algorithm that periodically detects spam accounts.                                                                                                      |
| [decidim-term_customizer](https://github.com/mainio/decidim-module-term_customizer)                                     | ✅       | Allows customization of translated strings.                                                                                                                                   |
| [decidim-gallery](https://github.com/alecslupu-pfa/decidim-module-gallery)                                              | ✅       | Enables the creation of galleries.                                                                                                                                            |
| [decidim-extra_user_fields](https://github.com/PopulateTools/decidim-module-extra_user_fields)                          | ✅       | Allows the creation of new fields in the user form.                                                                                                                           |
| [decidim-custom_proposal_states](https://github.com/alecslupu-pfa/decidim-module-custom_proposal_states)                | ✅       | Allows more than 3 proposal states.                                                                                                                                           |
| [decidim-survey_multiple_answers](https://github.com/OpenSourcePolitics/decidim-module-survey_multiple_answers)         | ✅       | Allows multiple answers in surveys.                                                                                                                                           |
| [decidim-simple-proposal](https://github.com/OpenSourcePolitics/decidim-module-simple_proposal)                         | ✅       | Reduces the number of steps in proposal creation.                                                                                                                             |
| [decidim-half_signup](https://github.com/OpenSourcePolitics/decidim-module-half_sign_up.git)                            | ✅       | Allows the creation of half accounts used just to vote.                                                                                                                       |
| [decidim-anonymous-proposals](https://github.com/PopulateTools/decidim-module-anonymous_proposals)                      | ✅       | Allows the creation of anonymous proposals.                                                                                                                                   |
| [decidim-budget_category_voting](https://github.com/alecslupu-pfa/decidim-budget_category_voting.git)                   | ✅       | Imposes category quotas in budgets.                                                                                                                                           |
| [decidim-budgets_booth](https://github.com/OpenSourcePolitics/decidim-module-ptp)                   | ✅       | Hides all the clutter away when voting in a budget.                                                                                                                                           |



Some non-official customizations can be found see [OVERLOADS.MD](./OVERLOADS.md).

## 🚀 Getting started
- See our [installation guide](./docs/GETTING_STARTED.md) to run a decidim-app by OSP locally
- See our [Docker installation guide](./docs/GETTING_STARTED_DOCKER.md) to run a decidim-app by OSP locally with Docker
- See our [homepage interactive map module](./docs/HOMEPAGE_INTERACTIVE_MAP.md) to configure module (OSX/Ubuntu)

## 👋 Contributing
- See our [contributing guide](./docs/CONTRIBUTING.md)

## 🔒 Security
Security is very important to us. If you have any issue regarding security, please disclose the information responsibly by sending an email to **security[at]opensourcepolitics[dot]eu** and not by creating a Github issue. 

## License
The decidim-app is licensed under the [AGPLv3](./LICENSE-AGPLV3.txt), same license as Decidim.
