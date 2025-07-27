# ExMgrs

[![Hex.pm](https://img.shields.io/hexpm/v/ex_mgrs.svg)](https://hex.pm/packages/ex_mgrs)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_mgrs.svg)](https://hex.pm/packages/ex_mgrs)
[![GitHub Actions](https://github.com/cortfritz/ex_mgrs/workflows/CI%2FCD%20Pipeline/badge.svg)](https://github.com/cortfritz/ex_mgrs/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Elixir library for converting between latitude/longitude coordinates and MGRS (Military Grid Reference System) coordinates. Built with Rust NIFs for maximum speed and accuracy using the embedded [geoconvert-rs](https://github.com/cortfritz/geoconvert-rs) Rust library.

## Features
Is a bare minimum of features needed to work with lat/lon and mgrs.
- **High Performance**: Rust NIFs provide near-native speed for coordinate conversions
- **Bidirectional**: Convert lat/lon to MGRS and MGRS to lat/lon
- **Precision Control**: Configurable precision levels (1-5 digits, default 5)
- **Self-contained**: Embedded Rust library for easy Hex installation

## Quick Start

```elixir
# Add to mix.exs
{:ex_mgrs, "~> 0.0.3"}

# Install and compile
mix deps.get
mix compile

# Use in your code
iex> ExMgrs.latlon_to_mgrs(34.0, -118.24)
{:ok, "11SLT8548562848"}

iex> ExMgrs.mgrs_to_latlon("11SLT8548562848")
{:ok, {34.0, -118.24}}
```

## Installation

### From Hex (Recommended)

Add `ex_mgrs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_mgrs, "~> 0.0.3"}
  ]
end
```

Then run:

```bash
mix deps.get
mix compile
```

**Note:** This package uses Rust NIFs and requires Rust to be installed for compilation. The Rust toolchain will be automatically managed by Rustler during the build process.

### From Source (Development)

If you want to contribute or use the latest development version:

```bash
# Clone with submodules to get the geoconvert library
git clone --recursive https://github.com/cortfritz/ex_mgrs.git
cd ex_mgrs

# If you already cloned without --recursive, initialize submodules:
git submodule update --init --recursive

# Install dependencies and compile
mix deps.get
mix compile

# Run tests
mix test
```

## Usage

### Basic Conversions

```elixir
# Convert latitude/longitude to MGRS
iex> ExMgrs.latlon_to_mgrs(34.0, -118.24, 5)
{:ok, "11SLT8548562848"}

# Convert MGRS to latitude/longitude
iex> ExMgrs.mgrs_to_latlon("11SLT8548562848")
{:ok, {34.0, -118.24}}

# Use different precision levels
iex> ExMgrs.latlon_to_mgrs(34.0, -118.24, 3)
{:ok, "11SLT854628"}
```

### Precision Levels

MGRS precision determines the accuracy of the coordinate:

| Precision | Accuracy | Example |
|-----------|----------|---------|
| 1 | 10 km | `"11SLT8"` |
| 2 | 1 km | `"11SLT85"` |
| 3 | 100 m | `"11SLT854"` |
| 4 | 10 m | `"11SLT8548"` |
| 5 | 1 m | `"11SLT85485"` |

### Error Handling

```elixir
# Invalid coordinates
iex> ExMgrs.latlon_to_mgrs(91.0, 0.0)
{:error, "Invalid coordinates: Latitude must be between -90 and 90 degrees"}

# Invalid MGRS string
iex> ExMgrs.mgrs_to_latlon("invalid")
{:error, {0.0, 0.0}}
```

## API Reference

### `ExMgrs.latlon_to_mgrs(lat, lon, precision \\ 5)`

Converts latitude/longitude coordinates to MGRS format.

**Parameters:**
- `lat` (number): Latitude in decimal degrees (-90.0 to 90.0)
- `lon` (number): Longitude in decimal degrees (-180.0 to 180.0)
- `precision` (integer): Number of digits for easting/northing (1-5, default: 5)

**Returns:**
- `{:ok, mgrs_string}` on success
- `{:error, reason}` on failure

### `ExMgrs.mgrs_to_latlon(mgrs)`

Converts MGRS coordinates to latitude/longitude format.

**Parameters:**
- `mgrs` (string): MGRS coordinate string

**Returns:**
- `{:ok, {latitude, longitude}}` on success where coordinates are in decimal degrees
- `{:error, {0.0, 0.0}}` on failure

## Development

### Prerequisites

- Elixir 1.18.2+
- Rust (managed by Rustler)
- Git (for submodules)

### Setup

```bash
# Clone the repository with submodules (for development)
git clone --recursive https://github.com/cortfritz/ex_mgrs.git
cd ex_mgrs

# If you already cloned without --recursive, initialize submodules:
git submodule update --init --recursive

# Install dependencies
mix deps.get

# Compile (includes Rust NIF compilation)
mix compile

# Run tests
mix test

# Format code
mix format

# Run static analysis
mix dialyzer
```

### Architecture

This library includes coordinate conversion functionality in two ways:

**For Development:**

- `native/geoconvert/` - Git submodule pointing to the [geoconvert-rs](https://github.com/cortfritz/geoconvert-rs) fork
- To update from upstream: `git submodule update --remote`

**For Hex Packages:**

- `native/geoconvert_embedded/` - Embedded copy of geoconvert source included in Hex packages
- Ensures users can install from Hex without needing git submodules

**Common Structure:**

- `lib/ex_mgrs.ex` - Main public API
- `lib/ex_mgrs/native.ex` - NIF interface
- `native/geoconvert_nif/` - Thin Rust NIF wrapper that interfaces with geoconvert

## Contributing

We welcome contributions! Please follow these guidelines:

### Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes following the project conventions
4. Ensure tests pass: `mix test`
5. Run static analysis: `mix dialyzer`
6. Format your code: `mix format`
7. Commit with a descriptive message
8. Push and create a pull request

### Development Guidelines

- Follow Elixir community conventions
- Add tests for new functionality
- Update documentation as needed
- Ensure NIFs compile successfully
- Validate roundtrip conversions in tests
- Run `mix dialyzer` to check for type issues

### Reporting Issues

Please use GitHub Issues to report bugs or request features. Include:

- Elixir and Rust versions
- Operating system
- Steps to reproduce
- Expected vs actual behavior
- Any error messages or stack traces

## Troubleshooting

### Common Issues

**Rust not found:**
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

**Compilation errors:**
```bash
# Clean and rebuild
mix clean
mix deps.clean --all
mix deps.get
mix compile
```

**Submodule issues:**
```bash
# Reinitialize submodules
git submodule deinit -f .
git submodule update --init --recursive
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

```bash
mix docs
```

Docs available at <https://hexdocs.pm/ex_mgrs>.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.
