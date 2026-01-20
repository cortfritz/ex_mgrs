# ExMgrs

Elixir library for converting between latitude/longitude coordinates and MGRS (Military Grid Reference System) coordinates. Built with Rust NIFs for maximum speed and accuracy using the embedded [geoconvert-rs](https://github.com/ncrothers/geoconvert-rs) Rust library.

## Features

- Convert decimal degrees (lat/lon) to MGRS grid reference string
- Convert MGRS grid reference string back to decimal degrees
- Format MGRS strings with proper spacing
- Configurable precision levels (1-5 digits, default 5)

## Installation

### From Hex (Recommended)

Add `ex_mgrs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_mgrs, "~> 0.0.5"}
  ]
end
```

Then run:

```bash
mix deps.get
mix compile
```

**Note:** This package uses precompiled Rust NIFs for fast installation. **No Rust toolchain is required** for most platforms (macOS, Linux, Windows). Precompiled binaries are automatically downloaded during installation.

If precompiled binaries are not available for your platform, the package will automatically fall back to compiling from source, which requires the Rust toolchain to be installed.

#### Supported Platforms

Precompiled binaries are provided for:
- **macOS**: x86_64 (Intel), aarch64 (Apple Silicon)
- **Linux**: x86_64 (glibc), x86_64 (musl), aarch64 (glibc), aarch64 (musl)
- **Windows**: x86_64 (MSVC), x86_64 (GNU)

#### Force Build from Source

To force compilation from source instead of using precompiled binaries:

```bash
RUSTLER_PRECOMPILATION_EXAMPLE_BUILD=true mix deps.compile ex_mgrs --force
```

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

# Format MGRS string with proper spacing
iex> ExMgrs.format_mgrs("11SLT8548562848")
{:ok, "11S LT 85485 62848"}

# Works with already-formatted strings too
iex> ExMgrs.format_mgrs("11S LT 85485 62848")
{:ok, "11S LT 85485 62848"}

# Use different precision levels
iex> ExMgrs.latlon_to_mgrs(34.0, -118.24, 3)
{:ok, "11SLT854628"}

iex> ExMgrs.format_mgrs("11SLT854628")
{:ok, "11S LT 854 628"}
```

## Development

### Prerequisites

- Elixir >= 1.18.2 and <= 1.19.2
- Rust (managed by Rustler)
- Git (for submodules when developing from source)

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

**Note:** This project includes a `mise.toml` file configured for Elixir 1.19.2-otp-28. If you use [mise](https://mise.jdx.dev/), it will automatically use this version. You can override this locally or use any version within the required range (>= 1.18.2 and <= 1.19.2) with your preferred version manager.

### Architecture

This library includes coordinate conversion functionality in two ways:

**For Development:**

- `native/geoconvert/` - Git submodule pointing to the upstream [geoconvert-rs](https://github.com/ncrothers/geoconvert-rs) repository
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

- Elixir version (required: >= 1.18.2 and <= 1.19.2)
- Rust version
- Rustler version (this project uses ~> 0.36)
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
