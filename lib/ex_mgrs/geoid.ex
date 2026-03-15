defmodule ExMgrs.Geoid do
  @moduledoc """
  EGM96 geoid undulation lookup and conversions between HAE (Height Above Ellipsoid)
  and MSL (Mean Sea Level) heights.

  Uses the EGM96 15-minute global geoid undulation grid to convert between WGS84
  ellipsoidal height and height above mean sea level. The geoid undulation (N) is the
  difference between the two: `HAE = MSL + N` and `MSL = HAE - N`.

  All functions accept coordinates as lat/lon, ECEF tuples, or MGRS strings.

  Functions named with `alt` are aliases for their `hae` counterparts -- `alt` is
  always HAE (Height Above Ellipsoid) in this module.
  """

  @grid_rows 721
  @grid_cols 1440
  @cell_size 0.25

  # GeographicLib PGM encoding: undulation = offset + scale * pixel_value
  @offset -108.0
  @scale 0.003

  @egm96_path Application.app_dir(:ex_mgrs, "priv/egm96-15.bin")
  @external_resource @egm96_path

  @grid_binary File.read!(@egm96_path)

  # ---------------------------------------------------------------------------
  # Geoid undulation
  # ---------------------------------------------------------------------------

  @doc """
  Returns the geoid undulation (N) in meters at the given latitude and longitude.

  The geoid undulation is the height of the geoid (approximation of mean sea level)
  above the WGS84 ellipsoid. Values range from roughly -106m to +85m globally.

  Uses bilinear interpolation on the EGM96 15-minute grid.

  ## Parameters
  - `lat` - Latitude in decimal degrees (-90.0 to 90.0)
  - `lon` - Longitude in decimal degrees (-180.0 to 180.0)

  ## Returns
  - `{:ok, undulation}` in meters
  - `{:error, reason}` on invalid input

  ## Examples

      iex> {:ok, n} = ExMgrs.Geoid.undulation(0.0, 0.0)
      ...> is_float(n)
      true

  """
  def undulation(lat, lon) when is_number(lat) and is_number(lon) do
    cond do
      lat < -90.0 or lat > 90.0 ->
        {:error, "latitude must be between -90 and 90"}

      lon < -180.0 or lon > 180.0 ->
        {:error, "longitude must be between -180 and 180"}

      true ->
        {:ok, interpolate(lat, lon)}
    end
  end

  # ---------------------------------------------------------------------------
  # HAE <-> MSL (scalar height conversions)
  # ---------------------------------------------------------------------------

  @doc """
  Converts HAE (Height Above Ellipsoid) to MSL (Mean Sea Level) height.

  `MSL = HAE - N` where N is the geoid undulation.

  ## Parameters
  - `lat` - Latitude in decimal degrees
  - `lon` - Longitude in decimal degrees
  - `hae` - Height above WGS84 ellipsoid in meters

  ## Returns
  - `{:ok, msl}` height above mean sea level in meters

  ## Examples

      iex> {:ok, msl} = ExMgrs.Geoid.hae_to_msl(0.0, 0.0, 100.0)
      ...> is_float(msl)
      true

  """
  def hae_to_msl(lat, lon, hae)
      when is_number(lat) and is_number(lon) and is_number(hae) do
    with {:ok, n} <- undulation(lat, lon) do
      {:ok, hae - n}
    end
  end

  @doc """
  Alias for `hae_to_msl/3`.

  See `hae_to_msl/3` for full documentation.
  """
  def alt_to_msl(lat, lon, alt), do: hae_to_msl(lat, lon, alt)

  @doc """
  Converts MSL (Mean Sea Level) height to HAE (Height Above Ellipsoid).

  `HAE = MSL + N` where N is the geoid undulation.

  ## Parameters
  - `lat` - Latitude in decimal degrees
  - `lon` - Longitude in decimal degrees
  - `msl` - Height above mean sea level in meters

  ## Returns
  - `{:ok, hae}` height above WGS84 ellipsoid in meters

  ## Examples

      iex> {:ok, hae} = ExMgrs.Geoid.msl_to_hae(0.0, 0.0, 100.0)
      ...> is_float(hae)
      true

  """
  def msl_to_hae(lat, lon, msl)
      when is_number(lat) and is_number(lon) and is_number(msl) do
    with {:ok, n} <- undulation(lat, lon) do
      {:ok, msl + n}
    end
  end

  @doc """
  Alias for `msl_to_hae/3`.

  See `msl_to_hae/3` for full documentation.
  """
  def msl_to_alt(lat, lon, msl), do: msl_to_hae(lat, lon, msl)

  # ---------------------------------------------------------------------------
  # Lat/Lon + MSL <-> ECEF
  # ---------------------------------------------------------------------------

  @doc """
  Converts latitude, longitude, and MSL altitude to ECEF coordinates.

  Converts the MSL height to HAE using the EGM96 geoid, then computes ECEF.

  ## Parameters
  - `lat` - Latitude in decimal degrees (-90.0 to 90.0)
  - `lon` - Longitude in decimal degrees (-180.0 to 180.0)
  - `msl` - Height above mean sea level in meters (default: 0.0)

  ## Returns
  - `{:ok, {x, y, z}}` ECEF coordinates in meters
  - `{:error, reason}` on invalid input

  ## Examples

      iex> {:ok, {x, _y, _z}} = ExMgrs.Geoid.latlon_msl_to_ecef(0.0, 0.0, 0.0)
      ...> round(x)
      6378154

  """
  def latlon_msl_to_ecef(lat, lon, msl \\ 0.0)
      when is_number(lat) and is_number(lon) and is_number(msl) do
    with {:ok, hae} <- msl_to_hae(lat, lon, msl) do
      ExMgrs.Ecef.from_latlon_hae(lat, lon, hae)
    end
  end

  @doc """
  Converts ECEF coordinates to latitude, longitude, and MSL altitude.

  First converts ECEF to lat/lon/HAE, then adjusts for geoid undulation.

  ## Returns
  - `{:ok, {lat, lon, msl}}` in decimal degrees and meters

  ## Examples

      iex> {:ok, {_lat, _lon, msl}} = ExMgrs.Geoid.ecef_to_latlon_msl(6_378_237.0, 0.0, 0.0)
      ...> is_float(msl)
      true

  """
  def ecef_to_latlon_msl(x, y, z) when is_number(x) and is_number(y) and is_number(z) do
    with {:ok, {lat, lon, hae}} <- ExMgrs.Ecef.to_latlon_hae(x, y, z),
         {:ok, n} <- undulation(lat, lon) do
      {:ok, {lat, lon, hae - n}}
    end
  end

  # ---------------------------------------------------------------------------
  # MGRS + MSL <-> ECEF
  # ---------------------------------------------------------------------------

  @doc """
  Converts an MGRS coordinate string and MSL altitude to ECEF coordinates.

  ## Parameters
  - `mgrs` - MGRS coordinate string
  - `msl` - Height above mean sea level in meters (default: 0.0)

  ## Returns
  - `{:ok, {x, y, z}}` ECEF coordinates in meters
  - `{:error, reason}` on invalid input

  ## Examples

      iex> {:ok, {x, y, z}} = ExMgrs.Geoid.mgrs_msl_to_ecef("11SLT8548562848", 0.0)
      ...> {is_float(x), is_float(y), is_float(z)}
      {true, true, true}

  """
  def mgrs_msl_to_ecef(mgrs, msl \\ 0.0) when is_binary(mgrs) and is_number(msl) do
    with {:ok, {lat, lon}} <- ExMgrs.mgrs_to_latlon(mgrs),
         {:ok, hae} <- msl_to_hae(lat, lon, msl) do
      ExMgrs.Ecef.from_latlon_hae(lat, lon, hae)
    end
  end

  @doc """
  Converts ECEF coordinates to MGRS string and MSL altitude.

  ## Parameters
  - `x` - X coordinate in meters
  - `y` - Y coordinate in meters
  - `z` - Z coordinate in meters
  - `precision` - MGRS precision 1-5 (default: 5)

  ## Returns
  - `{:ok, {mgrs, msl}}` where mgrs is the MGRS string and msl is meters above mean sea level
  - `{:error, reason}` on invalid input

  ## Examples

      iex> {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon(34.0, -118.24, 100.0)
      ...> {:ok, {mgrs, msl}} = ExMgrs.Geoid.ecef_to_mgrs_msl(x, y, z)
      ...> {String.starts_with?(mgrs, "11S"), is_float(msl)}
      {true, true}

  """
  def ecef_to_mgrs_msl(x, y, z, precision \\ 5)
      when is_number(x) and is_number(y) and is_number(z) and is_integer(precision) do
    with {:ok, {lat, lon, hae}} <- ExMgrs.Ecef.to_latlon_hae(x, y, z),
         {:ok, mgrs} <- ExMgrs.latlon_to_mgrs(lat, lon, precision),
         {:ok, n} <- undulation(lat, lon) do
      {:ok, {mgrs, hae - n}}
    end
  end

  # ---------------------------------------------------------------------------
  # MGRS + HAE -> MSL and MGRS + MSL -> HAE
  # ---------------------------------------------------------------------------

  @doc """
  Returns the MSL altitude for an MGRS coordinate at the given HAE.

  ## Parameters
  - `mgrs` - MGRS coordinate string
  - `hae` - Height above WGS84 ellipsoid in meters (default: 0.0)

  ## Returns
  - `{:ok, {lat, lon, msl}}` in decimal degrees and meters

  ## Examples

      iex> {:ok, {_lat, _lon, msl}} = ExMgrs.Geoid.mgrs_hae_to_msl("11SLT8548562848", 100.0)
      ...> is_float(msl)
      true

  """
  def mgrs_hae_to_msl(mgrs, hae \\ 0.0) when is_binary(mgrs) and is_number(hae) do
    with {:ok, {lat, lon}} <- ExMgrs.mgrs_to_latlon(mgrs),
         {:ok, n} <- undulation(lat, lon) do
      {:ok, {lat, lon, hae - n}}
    end
  end

  @doc """
  Alias for `mgrs_hae_to_msl/2`. The `alt` parameter is HAE (Height Above Ellipsoid).

  See `mgrs_hae_to_msl/2` for full documentation.
  """
  def mgrs_alt_to_msl(mgrs, alt \\ 0.0), do: mgrs_hae_to_msl(mgrs, alt)

  @doc """
  Returns the HAE for an MGRS coordinate at the given MSL altitude.

  ## Parameters
  - `mgrs` - MGRS coordinate string
  - `msl` - Height above mean sea level in meters (default: 0.0)

  ## Returns
  - `{:ok, {lat, lon, hae}}` in decimal degrees and meters

  ## Examples

      iex> {:ok, {_lat, _lon, hae}} = ExMgrs.Geoid.mgrs_msl_to_hae("11SLT8548562848", 100.0)
      ...> is_float(hae)
      true

  """
  def mgrs_msl_to_hae(mgrs, msl \\ 0.0) when is_binary(mgrs) and is_number(msl) do
    with {:ok, {lat, lon}} <- ExMgrs.mgrs_to_latlon(mgrs),
         {:ok, n} <- undulation(lat, lon) do
      {:ok, {lat, lon, msl + n}}
    end
  end

  @doc """
  Alias for `mgrs_msl_to_hae/2`.

  See `mgrs_msl_to_hae/2` for full documentation.
  """
  def mgrs_msl_to_alt(mgrs, msl \\ 0.0), do: mgrs_msl_to_hae(mgrs, msl)

  # ---------------------------------------------------------------------------
  # Deprecated aliases for backwards compatibility
  # ---------------------------------------------------------------------------

  @doc false
  def ellipsoid_to_msl(lat, lon, hae), do: hae_to_msl(lat, lon, hae)
  @doc false
  def msl_to_ellipsoid(lat, lon, msl), do: msl_to_hae(lat, lon, msl)
  @doc false
  def ecef_to_msl(x, y, z), do: ecef_to_latlon_msl(x, y, z)
  @doc false
  def mgrs_to_msl(mgrs, hae \\ 0.0), do: mgrs_hae_to_msl(mgrs, hae)
  @doc false
  def msl_to_ecef(lat, lon, msl \\ 0.0), do: latlon_msl_to_ecef(lat, lon, msl)

  # ---------------------------------------------------------------------------
  # Private: bilinear interpolation on the EGM96 grid
  # ---------------------------------------------------------------------------

  defp interpolate(lat, lon) do
    # Grid origin is 90N, 0E. Rows go south, columns go east.
    # 1440 columns cover 0E to 359.75E (wraps at 360)
    lon_pos = if lon < 0.0, do: lon + 360.0, else: lon

    row_f = (90.0 - lat) / @cell_size
    col_f = lon_pos / @cell_size

    row0 = trunc(row_f)
    col0 = trunc(col_f)

    row1 = min(row0 + 1, @grid_rows - 1)
    col1 = rem(col0 + 1, @grid_cols)

    dr = row_f - row0
    dc = col_f - col0

    v00 = grid_value(row0, col0)
    v01 = grid_value(row0, col1)
    v10 = grid_value(row1, col0)
    v11 = grid_value(row1, col1)

    # Bilinear interpolation
    v00 * (1.0 - dr) * (1.0 - dc) +
      v01 * (1.0 - dr) * dc +
      v10 * dr * (1.0 - dc) +
      v11 * dr * dc
  end

  defp grid_value(row, col) do
    offset = (row * @grid_cols + col) * 2
    <<_::binary-size(offset), pixel::big-unsigned-integer-16, _::binary>> = @grid_binary
    @offset + @scale * pixel
  end
end
