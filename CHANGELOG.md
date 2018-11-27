# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),

## [Unreleased]

### Changed

- Make nginx-ee more modular
- Add support for Debian 9
- Add support for Raspbian
- Improve documentation

## [3.3.2] - 2018-11-27

### Added

- Add changelog
- add compilation summary

### Changed

- fix nginx compilation arguments
- cleanup code
- openssl version bump to 1.1.1a

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