# ExMgrs

Elixir library for converting between latitude/longitude coordinates and MGRS (Military Grid Reference System) coordinates. Built with Rust NIFs for maximum speed and accuracy using the embedded [geoconvert-rs](https://github.com/cortfritz/geoconvert-rs) Rust library.

## Features

- Convert decimal degrees (lat/lon) to MGRS grid reference string
- Convert MGRS grid reference string back to decimal degrees
- Configurable precision levels (1-5 digits, default 5)

## Installation

### From Hex (Recommended)

Add `ex_mgrs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_mgrs, "~> 0.0.1"}
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

## Development

### Prerequisites

- Elixir 1.12+
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
5. Format your code: `mix format`
6. Commit with a descriptive message
7. Push and create a pull request

### Development Guidelines

- Follow Elixir community conventions
- Add tests for new functionality
- Update documentation as needed
- Ensure NIFs compile successfully
- Validate roundtrip conversions in tests

### Reporting Issues

Please use GitHub Issues to report bugs or request features. Include:

- Elixir and Rust versions
- Operating system
- Steps to reproduce
- Expected vs actual behavior

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

```bash
mix docs
```

Once published to Hex, docs will be available at <https://hexdocs.pm/ex_mgrs>.
