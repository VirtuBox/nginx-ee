# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),

## [Unreleased] - XX-XX-XX

## [3.6.7] - 2020-08-18

### Changed

- Compile with gcc-9

### Fixed

- wrong PPA repositories with Ubuntu 20.04

## [3.6.6] - 2020-05-02

### Changed

- Update Nginx stable to 1.18.0
- Update openssl package to 1.1.1g

### Fixed

- Fix final tasks not executed (PR [#90])
- Fix non interactive pagespeed build (PR [#90])

## [3.6.5] - 2019-11-18

### Added

- Dynamic modules configuration
- Added Ubuntu EOAN (19.10) support

### Changed

- Bump OpenSSL version to 1.1.1d
- Updated ngx_brotli module
- Bump LibreSSL version to 3.0.2
- Fix issue with ngx_http_redis module download
- Update OpenSSL 3.0.0-dev commit number and patch

### Fixed

- dpkg-buildflags variable set before installing dpkg-dev

## [3.6.4] - 2019-08-29

### Added

- Debian 10 (buster) support
- Raspbian 10 (buster) support

### Changed

- Updated cronjob
- Improve module cloning duration by adding `--depth=50` to `git clone`
- PCRE, OPENSSL & Brotli are not compiled anymore. But are installed from [APT repository](https://build.opensuse.org/project/show/home:virtubox:nginx-ee) excepted Brotli on Debian 8 (jessie)
- Decrease build duration by 2

## [3.6.3] - 2019-07-15

### Added

- Ubuntu 19.04 (disco) support
- Strip Nginx binary to remove debug symbols
- Update OpenSSL to release 1.1.1c
- Added help menu

### Changed

- Improve code quality according to codacy checkup
- Brotli bumped to v1.0.7
- Only third party modules are compiled as dynamic modules

### Fixed

- Missing OpenSSL patch

## [3.6.2] - 2019-04-24

### Added

- Additional GCC flags : "-Wno-error=date-time for Debian" : PR [#52](https://github.com/VirtuBox/nginx-ee/pull/52)

### Changed

- Update LibreSSL to v2.9.1
- Update Nginx stable to 1.16.0

## [3.6.1] - 2019-04-19

### Added

- Latest Pcre version auto-update

### Fixed

- OpenSSL selection from script arguments
- Pcre library update

## [3.6.0] - 2019-04-18

### Added

- LibreSSL support with the flag --libressl
- OpenSSL release choice : 1.1.1b by default, or 3.0.0-dev or system lib

### Changed

- Improve Nginx setup from scratch
- Update openssl-patch
- Nginx is compiled with OpenSSL 1.1.1b stable by default
- Update PCRE LIB to v8.43

### Fixed

- RTMP variable check
- Nginx package hold with WordOps

## [3.5.2] - 2019-02-18

### Changed

- fix debian 8 build
- fix dynamic modules choice

## [3.5.1] - 2019-02-07

### Changed

- improve openssl download and patching
- improve code quality
- improve travis build configuration
- update repository image

### Added

- add infos about auto-update cronjob
- Add support for Raspbian Stretch
- Add Cloudflare zlib
- Add dynamic module compilation in interactive installation menu
- Add cronjob setup in interactive installation menu

## [3.5.0] - 2018-12-26

### Changed

- uwsgi support re-added
- set back apt-mark hold on sw-nginx package for Plesk

### Added

- added daily cronjob for automated update
- Add support for Debian 9 & Raspbian

## [3.4.0] - 2018-12-26

### Changed

- Fix gcc setup with nginx stable release
- Fix arguments parsing for non-interactive install
- By default Nginx-ee compile the latest mainline release without optional modules like pagespeed or naxsi
- Fix wrong Nginx version displayed in the compilation summary

### Added

- Interactive install can be launched with the argument -i or --interactive
- Add WordOps detection

## [3.3.3] - 2018-12-07

### Changed

- Fix RTMP module choice by @Madic- [Pull request #23](https://github.com/VirtuBox/nginx-ee/pull/23)
- Update openssl-patch url

## [3.3.2] - 2018-11-27

### Added

- Add changelog
- add compilation summary

### Changed

- fix nginx compilation arguments
- cleanup code
- openssl version bump to 1.1.2-dev

## [3.3.1] - 2018-11-16

### Changed

- fix nginx version detection
- cleanup code
- update github page

## [3.3.0] - 2018-11-15

### Changed

- Add the ability to override official & third-party modules built with nginx-ee
- Automate nginx release number detection for mainline and stable release
- Do not lock nginx packages updates with apt-mark anymore but directly with /etc/apt/preferences.d/