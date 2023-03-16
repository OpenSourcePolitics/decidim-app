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

You can find below an exhaustive list of modules with their repository links and latest version available :


| Decidim Module                      | Version |             Brief description                                    |
|-------------------------------------|---------|------------------------------------------------------------------|
| decidim-core                        | v0.26.2 |
| decidim-conferences                 | v0.26.2 |
| [decidim-cache_cleaner](https://github.com/OpenSourcePolitics/decidim-module-cache_cleaner)               | ✅      |Allow admins to clear cache of the application in the back-office|
| [decidim-decidim_awesome](https://github.com/decidim-ice/decidim-module-decidim_awesome)             | ✅      |An awesome module that allows (among others) : adding extra-fields for proposals creation, fullscreen iframe component, image in rich text editor, customs redirections etc. |
| [decidim-friendly_signup](https://github.com/OpenSourcePolitics/decidim-module-friendly_signup)             | ✅      |Module that drastically simplify the registration process of users by deleting some registration fields|
| [decidim-homepage_interactive_map](https://github.com/OpenSourcePolitics/decidim-module-homepage_interactive_map)    | ✅      |Module that allow the adding of a content-block on the homepage diplaying a map of assemblies in order to allow geo-located participation |
| [decidim-ludens](https://github.com/OpenSourcePolitics/decidim-ludens)                      | ✅      |Gamified tutorial in the admin back-office to help admins understand how Decidim works|
| [decidim-phone_authorization_handler](https://github.com/OpenSourcePolitics/decidim-module_phone_authorization_handler) | ✅      |Module allowing gathering phone number on a particular participant action|
| [decidim-spam_detection](https://github.com/OpenSourcePolitics/decidim-spam_detection)              | ✅      |Module adding a spam detection algorithm that runs periodically detecting spam accounts|
| [decidim-term_customizer](https://github.com/mainio/decidim-module-term_customizer)             | ✅      |Module allowing the change of translated strings |


Some non-official customizations can be found see [OVERLOADS.MD](./OVERLOADS.md).

## 🚀 Getting started
- See our [installation guide](./docs/GETTING_STARTED.md) for mode information

## 👋 Contributing
- See our [contributing guide](./docs/CONTRIBUTING.md)

## 🔒 Security
Security is very important to us. If you have any issue regarding security, please disclose the information responsibly by sending an email to **security[at]opensourcepolitics[dot]eu** and not by creating a Github issue. 

## License
The decidim-app is licensed under the [AGPLv3](./LICENSE-AGPLV3.txt), same license as Decidim.