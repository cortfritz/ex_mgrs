# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-03-15

### Build

- Add conventional commits enforcement via commit-msg hook
- Add git_ops for changelog generation and version management
- Add git_hooks with pre-push hook for tests and format check
- Include CHANGELOG.md in hex package
- Add changelog link to hex.pm package page

## [0.1.0] - 2026-03-15

### Features

- Add ECEF (Earth-Centered, Earth-Fixed) coordinate conversions
- Add EGM96 geoid model with embedded 15-minute undulation grid
- Add MSL (Mean Sea Level) altitude conversions
- Full conversion matrix between lat/lon, MGRS, and ECEF with both HAE and MSL
- Add `alt` aliases alongside `hae` for user-friendly API

### Chores

- Bump version to 0.1.0
- Include egm96-15.bin in hex package

## [0.0.15] - 2026-03-14

### Features

- Initial release with lat/lon to MGRS conversion via Rust NIF
- MGRS to lat/lon conversion
- MGRS string formatting
- Configurable precision levels (1-5)
- Precompiled NIF binaries for macOS, Linux, and Windows
