# ExMgrs

Elixir library for converting between latitude/longitude coordinates and MGRS (Military Grid Reference System) coordinates. Built with Rust NIFs for maximum speed and accuracy using the embedded [geoconvert-rs](https://github.com/ncrothers/geoconvert-rs) Rust library.

## Features

- Convert decimal degrees (lat/lon) to MGRS grid reference string
- Convert MGRS grid reference string back to decimal degrees
- Format MGRS strings with proper spacing
- Configurable precision levels (1-5 digits, default 5)
- ECEF (Earth-Centered, Earth-Fixed) coordinate conversions
- EGM96 geoid model for MSL (Mean Sea Level) altitude conversions
- Safe for the BEAM: no `unsafe` Rust code in application or geoconvert library

## Understanding Altitude: HAE vs MSL

This library works with two altitude systems. Understanding the difference matters when altitude accuracy is important (aviation, surveying, GPS integration):

**HAE (Height Above Ellipsoid)** -- also called "ellipsoidal height" or simply "alt" in GPS contexts. This is the raw geometric distance above the WGS84 reference ellipsoid, a smooth mathematical surface that approximates the Earth's shape. GPS receivers natively output HAE.

**MSL (Mean Sea Level)** -- the height above the geoid, a gravity-based surface that approximates actual sea level. This is what altimeters, aviation charts, topographic maps, and most real-world applications use.

The two differ by the **geoid undulation** (N) at each point on Earth:

```
HAE = MSL + N
MSL = HAE - N
```

The undulation varies from roughly -106m to +85m depending on location. For example, in Los Angeles the geoid is about 33m below the ellipsoid, so a GPS reading of 0m HAE corresponds to about 33m MSL.

This library uses the EGM96 geoid model (15-minute grid, ~2MB embedded at compile time) to convert between the two systems.

### Naming conventions

- Functions with `hae` in the name explicitly accept or return ellipsoidal height
- Functions with `msl` in the name accept or return mean sea level height
- Functions with `alt` in the name are aliases for their `hae` counterparts, for users more familiar with "altitude" than "HAE"
- In `ExMgrs.Ecef`, the default `from_latlon/3` and `from_mgrs/2` treat height as HAE

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

### MGRS Conversions

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

# Use different precision levels
iex> ExMgrs.latlon_to_mgrs(34.0, -118.24, 3)
{:ok, "11SLT854628"}
```

### ECEF Conversions

```elixir
# Lat/lon to ECEF (height is HAE, defaults to 0)
iex> ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 500.0)
{:ok, {-2_493_090.59, -4_655_089.08, 3_553_494.47}}

# Same thing using the alt alias
iex> ExMgrs.Ecef.from_latlon(34.0, -118.24, 500.0)
{:ok, {-2_493_090.59, -4_655_089.08, 3_553_494.47}}

# ECEF back to lat/lon/HAE
iex> ExMgrs.Ecef.to_latlon_hae(-2_493_090.59, -4_655_089.08, 3_553_494.47)
{:ok, {34.0, -118.24, 500.0}}

# MGRS to ECEF
iex> ExMgrs.Ecef.from_mgrs_hae("11SLT8548562848", 500.0)
{:ok, {-2_493_090.59, -4_655_089.08, 3_553_494.47}}

# ECEF to MGRS (returns {mgrs, hae})
iex> ExMgrs.Ecef.to_mgrs_hae(-2_493_090.59, -4_655_089.08, 3_553_494.47)
{:ok, {"11SLT8548562848", 500.0}}

# Euclidean distance between two ECEF points
iex> ExMgrs.Ecef.distance(point1, point2)
1234.56
```

### Geoid / MSL Conversions

```elixir
# Get geoid undulation at a location
iex> ExMgrs.Geoid.undulation(34.0, -118.24)
{:ok, -32.87}

# Convert between HAE and MSL
iex> ExMgrs.Geoid.hae_to_msl(34.0, -118.24, 500.0)
{:ok, 532.87}

iex> ExMgrs.Geoid.msl_to_hae(34.0, -118.24, 532.87)
{:ok, 500.0}

# alt aliases work the same way
iex> ExMgrs.Geoid.alt_to_msl(34.0, -118.24, 500.0)
{:ok, 532.87}

# Lat/lon + MSL to ECEF (converts through geoid automatically)
iex> ExMgrs.Geoid.latlon_msl_to_ecef(34.0, -118.24, 500.0)
{:ok, {x, y, z}}

# ECEF to lat/lon + MSL
iex> ExMgrs.Geoid.ecef_to_latlon_msl(x, y, z)
{:ok, {34.0, -118.24, 500.0}}

# MGRS + MSL to ECEF
iex> ExMgrs.Geoid.mgrs_msl_to_ecef("11SLT8548562848", 500.0)
{:ok, {x, y, z}}

# ECEF to MGRS + MSL
iex> ExMgrs.Geoid.ecef_to_mgrs_msl(x, y, z)
{:ok, {"11SLT8548562848", 500.0}}

# MGRS with altitude conversions
iex> ExMgrs.Geoid.mgrs_hae_to_msl("11SLT8548562848", 500.0)
{:ok, {34.0, -118.24, 532.87}}

iex> ExMgrs.Geoid.mgrs_msl_to_hae("11SLT8548562848", 532.87)
{:ok, {34.0, -118.24, 500.0}}
```

### Conversion Matrix

| From | To | Function |
|------|-----|----------|
| lat/lon + HAE | ECEF | `Ecef.from_latlon_hae/3` or `Ecef.from_latlon/3` |
| ECEF | lat/lon + HAE | `Ecef.to_latlon_hae/3` or `Ecef.to_latlon/3` |
| MGRS + HAE | ECEF | `Ecef.from_mgrs_hae/2` or `Ecef.from_mgrs/2` |
| ECEF | MGRS + HAE | `Ecef.to_mgrs_hae/4` or `Ecef.to_mgrs/4` |
| lat/lon + MSL | ECEF | `Geoid.latlon_msl_to_ecef/3` |
| ECEF | lat/lon + MSL | `Geoid.ecef_to_latlon_msl/3` |
| MGRS + MSL | ECEF | `Geoid.mgrs_msl_to_ecef/2` |
| ECEF | MGRS + MSL | `Geoid.ecef_to_mgrs_msl/4` |
| HAE | MSL | `Geoid.hae_to_msl/3` or `Geoid.alt_to_msl/3` |
| MSL | HAE | `Geoid.msl_to_hae/3` or `Geoid.msl_to_alt/3` |
| MGRS + HAE | lat/lon + MSL | `Geoid.mgrs_hae_to_msl/2` or `Geoid.mgrs_alt_to_msl/2` |
| MGRS + MSL | lat/lon + HAE | `Geoid.mgrs_msl_to_hae/2` or `Geoid.mgrs_msl_to_alt/2` |

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

- `lib/ex_mgrs.ex` - Main public API (lat/lon and MGRS conversions)
- `lib/ex_mgrs/ecef.ex` - ECEF coordinate conversions (pure Elixir)
- `lib/ex_mgrs/geoid.ex` - EGM96 geoid model and MSL conversions (pure Elixir)
- `lib/ex_mgrs/native.ex` - NIF interface
- `native/geoconvert_nif/` - Thin Rust NIF wrapper that interfaces with geoconvert
- `priv/egm96-15.bin` - EGM96 geoid undulation grid (embedded at compile time)

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

## Safety

This NIF is safe for your Elixir/Erlang host process:

- **Application code**: The NIF wrapper (`native/geoconvert_nif/`) contains no `unsafe` blocks
- **geoconvert library**: The embedded coordinate conversion library is 100% safe Rust
- **rustler**: The NIF binding library (v0.36) contains `unsafe` code internally to interface with the BEAM's C NIF API, but exposes only safe Rust APIs. Rustler catches Rust panics before they unwind into C, preventing BEAM crashes.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

```bash
mix docs
```

Once published to Hex, docs will be available at <https://hexdocs.pm/ex_mgrs>.
