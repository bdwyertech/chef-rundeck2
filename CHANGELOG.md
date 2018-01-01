Chef-RunDeck2 Changelog
=========================
This file is used to list changes made in each version of the `chef-rundeck2` gem.

v0.1.5 (2017-12-31)
-------------------
### Fix
- Fix permissions on gem files

v0.1.3 (2017-04-26)
-------------------
### Enhancements
- Allow customizing hostname:port value via Chef node attributes, API query params and project config file
- Sort Recipes & Tags
- Remove Recipes from Tags

v0.1.2 (2016-11-11)
-------------------
### Enhancements
- Security: Hide the config endpoint except in development mode

### Bugs Fixed
- Should automatically pick up the JSON config if developing locally and it is inside `config/config.json`

v0.1.1 (2016-06-09)
-------------------
- Initial Release