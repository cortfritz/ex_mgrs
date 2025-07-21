# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir project named `ex_mgrs` - a library for converting between latitude/longitude coordinates and MGRS (Military Grid Reference System) coordinates. It uses Rust NIFs for high-performance coordinate conversions via the embedded `geoconvert` Rust library.

## Common Commands

### Building and Dependencies
- `mix deps.get` - Install dependencies (including Rustler for NIF compilation)
- `mix compile` - Compile the project (includes Rust NIF compilation)
- `mix clean` - Clean compiled files

### Testing
- `mix test` - Run all tests including NIF roundtrip validation
- `mix test test/specific_test.exs` - Run a specific test file
- `mix test --cover` - Run tests with coverage report

### Development
- `mix format` - Format code according to Elixir standards
- `iex -S mix` - Start interactive Elixir shell with project loaded

### Documentation
- `mix docs` - Generate documentation (requires ex_doc dependency)

## Architecture

### Core Components
- `lib/ex_mgrs.ex` - Main module with public API for coordinate conversion
- `lib/ex_mgrs/native.ex` - Rustler NIF interface module
- `native/geoconvert/` - Embedded Rust geoconvert library (git submodule)
- `native/geoconvert_nif/` - Thin Rust NIF wrapper around geoconvert
- `test/ex_mgrs_test.exs` - Comprehensive tests including roundtrip validation

### NIF Implementation
The project embeds the `geoconvert-rs` Rust library as a git submodule for easy updates. A thin NIF wrapper provides two functions:

- `latlon_to_mgrs_nif/3` - Converts lat/lon coordinates to MGRS format
- `mgrs_to_latlon_nif/1` - Converts MGRS coordinates back to lat/lon

### Public API
- `ExMgrs.latlon_to_mgrs/3` - Convert decimal degrees to MGRS (precision 1-5, default 5)
- `ExMgrs.mgrs_to_latlon/1` - Convert MGRS string to {latitude, longitude} tuple

## Development Notes

- Uses Rustler 0.36 for NIF compilation
- Embedded geoconvert Rust library provides WGS84 ellipsoid calculations  
- Comprehensive test suite validates roundtrip conversions in both directions
- Tests include validation for specific coordinates (34.0, -118.24) → "11SLT8548562848"
- Project handles coordinate validation and error cases gracefully
- Ready for publication to Hex package manager