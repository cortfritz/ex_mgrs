# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced README with badges, quick start, and troubleshooting sections
- Comprehensive API documentation
- Precision level reference table
- Error handling examples

### Changed
- Updated embedded geoconvert library with clippy fixes
- Switched geoconvert submodule to fork for better maintenance
- Improved CI/CD workflow with repository restrictions

## [0.0.3] - 2024-07-27

### Added
- Initial release to Hex.pm
- Rust NIF implementation for high-performance coordinate conversion
- Bidirectional MGRS/lat-lon conversion
- Configurable precision levels (1-5 digits)
- Comprehensive test suite
- CI/CD pipeline with automated testing and publishing
- Dialyzer static analysis integration

### Technical Details
- Built with Rustler for Elixir/Rust interop
- Embedded geoconvert-rs library for self-contained Hex packages
- Git submodule setup for development workflow
- Cross-platform compatibility (Linux, macOS, Windows)

## [0.0.2] - Unreleased

### Changed
- Development version with initial NIF implementation

## [0.0.1] - Unreleased

### Added
- Initial project setup
- Basic Elixir library structure 