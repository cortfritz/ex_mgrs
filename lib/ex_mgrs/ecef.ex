defmodule ExMgrs.Ecef do
  @moduledoc """
  Converts between WGS84 latitude/longitude/altitude and ECEF (Earth-Centered, Earth-Fixed)
  Cartesian coordinates.

  ECEF represents points as (X, Y, Z) in meters from Earth's center of mass, where:
  - X axis points to 0 lat, 0 lon (intersection of equator and prime meridian)
  - Y axis points to 0 lat, 90 lon
  - Z axis points to the North Pole

  All altitude/height parameters in this module are **HAE (Height Above Ellipsoid)** --
  the geometric distance above the WGS84 reference ellipsoid. This is what GPS receivers
  natively output. If you need to work with MSL (Mean Sea Level) heights, see
  `ExMgrs.Geoid` which provides geoid-aware conversions.

  Functions named with `hae` accept or return ellipsoidal height explicitly. Functions
  named with `alt` are aliases that behave identically -- `alt` is always HAE in this module.
  """

  # WGS84 ellipsoid constants
  @a 6_378_137.0
  @f 1.0 / 298.257223563
  @b @a * (1.0 - @f)
  @e2 1.0 - @b * @b / (@a * @a)

  # ---------------------------------------------------------------------------
  # Lat/Lon <-> ECEF
  # ---------------------------------------------------------------------------

  @doc """
  Converts latitude, longitude, and HAE (Height Above Ellipsoid) to ECEF coordinates.

  ## Parameters
  - `lat` - Latitude in decimal degrees (-90.0 to 90.0)
  - `lon` - Longitude in decimal degrees (-180.0 to 180.0)
  - `hae` - Height above the WGS84 ellipsoid in meters (default: 0.0)

  ## Returns
  - `{:ok, {x, y, z}}` coordinates in meters
  - `{:error, reason}` on invalid input

  ## Examples

      iex> {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(0.0, 0.0, 0.0)
      ...> {round(x), round(y), round(z)}
      {6378137, 0, 0}

      iex> {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(90.0, 0.0, 0.0)
      ...> {round(x), round(y), round(z)}
      {0, 0, 6356752}

  """
  def from_latlon_hae(lat, lon, hae \\ 0.0)

  def from_latlon_hae(lat, lon, hae)
      when is_number(lat) and is_number(lon) and is_number(hae) do
    cond do
      lat < -90.0 or lat > 90.0 ->
        {:error, "latitude must be between -90 and 90"}

      lon < -180.0 or lon > 180.0 ->
        {:error, "longitude must be between -180 and 180"}

      true ->
        lat_rad = lat * :math.pi() / 180.0
        lon_rad = lon * :math.pi() / 180.0

        sin_lat = :math.sin(lat_rad)
        cos_lat = :math.cos(lat_rad)
        sin_lon = :math.sin(lon_rad)
        cos_lon = :math.cos(lon_rad)

        # Radius of curvature in the prime vertical
        n = @a / :math.sqrt(1.0 - @e2 * sin_lat * sin_lat)

        x = (n + hae) * cos_lat * cos_lon
        y = (n + hae) * cos_lat * sin_lon
        z = (n * (1.0 - @e2) + hae) * sin_lat

        {:ok, {x, y, z}}
    end
  end

  @doc """
  Alias for `from_latlon_hae/3`. The `alt` parameter is HAE (Height Above Ellipsoid).

  See `from_latlon_hae/3` for full documentation.
  """
  def from_latlon(lat, lon, alt \\ 0.0), do: from_latlon_hae(lat, lon, alt)

  @doc """
  Converts ECEF coordinates to latitude, longitude, and HAE.

  Uses Bowring's method for accurate results across all latitudes.

  ## Parameters
  - `x` - X coordinate in meters
  - `y` - Y coordinate in meters
  - `z` - Z coordinate in meters

  ## Returns
  - `{:ok, {lat, lon, hae}}` where lat/lon are decimal degrees and hae is meters
    above the WGS84 ellipsoid

  ## Examples

      iex> {:ok, {lat, lon, hae}} = ExMgrs.Ecef.to_latlon_hae(6378137.0, 0.0, 0.0)
      ...> {Float.round(lat, 6), Float.round(lon, 6), Float.round(hae, 1)}
      {0.0, 0.0, 0.0}

  """
  def to_latlon_hae(x, y, z) when is_number(x) and is_number(y) and is_number(z) do
    lon = :math.atan2(y, x)
    p = :math.sqrt(x * x + y * y)

    # Initial estimate using Bowring's formula
    theta = :math.atan2(z * @a, p * @b)
    sin_theta = :math.sin(theta)
    cos_theta = :math.cos(theta)

    lat =
      :math.atan2(
        z + (@a * @a - @b * @b) / @b * sin_theta * sin_theta * sin_theta,
        p - @e2 * @a * cos_theta * cos_theta * cos_theta
      )

    # One iteration for sub-millimeter accuracy
    sin_lat = :math.sin(lat)
    cos_lat = :math.cos(lat)
    n = @a / :math.sqrt(1.0 - @e2 * sin_lat * sin_lat)

    hae =
      if abs(cos_lat) > 1.0e-10 do
        p / cos_lat - n
      else
        abs(z) - @b
      end

    lat_deg = lat * 180.0 / :math.pi()
    lon_deg = lon * 180.0 / :math.pi()

    {:ok, {lat_deg, lon_deg, hae}}
  end

  @doc """
  Alias for `to_latlon_hae/3`. The returned altitude is HAE (Height Above Ellipsoid).

  See `to_latlon_hae/3` for full documentation.
  """
  def to_latlon(x, y, z), do: to_latlon_hae(x, y, z)

  # ---------------------------------------------------------------------------
  # MGRS <-> ECEF
  # ---------------------------------------------------------------------------

  @doc """
  Converts an MGRS coordinate string to ECEF coordinates.

  ## Parameters
  - `mgrs` - MGRS coordinate string
  - `hae` - Height above the WGS84 ellipsoid in meters (default: 0.0)

  ## Returns
  - `{:ok, {x, y, z}}` ECEF coordinates in meters
  - `{:error, reason}` on invalid input

  ## Examples

      iex> {:ok, {x, y, z}} = ExMgrs.Ecef.from_mgrs_hae("31NAA6602100000")
      ...> {is_float(x), is_float(y), is_float(z)}
      {true, true, true}

  """
  def from_mgrs_hae(mgrs, hae \\ 0.0) when is_binary(mgrs) and is_number(hae) do
    with {:ok, {lat, lon}} <- ExMgrs.mgrs_to_latlon(mgrs) do
      from_latlon_hae(lat, lon, hae)
    end
  end

  @doc """
  Alias for `from_mgrs_hae/2`. The `alt` parameter is HAE (Height Above Ellipsoid).

  See `from_mgrs_hae/2` for full documentation.
  """
  def from_mgrs(mgrs, alt \\ 0.0), do: from_mgrs_hae(mgrs, alt)

  @doc """
  Converts ECEF coordinates to an MGRS string and HAE.

  ## Parameters
  - `x` - X coordinate in meters
  - `y` - Y coordinate in meters
  - `z` - Z coordinate in meters
  - `precision` - MGRS precision 1-5 (default: 5)

  ## Returns
  - `{:ok, {mgrs, hae}}` where mgrs is the MGRS string and hae is ellipsoidal height
  - `{:error, reason}` on invalid input

  ## Examples

      iex> {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon(34.0, -118.24, 0.0)
      ...> {:ok, {mgrs, _hae}} = ExMgrs.Ecef.to_mgrs_hae(x, y, z)
      ...> String.starts_with?(mgrs, "11S")
      true

  """
  def to_mgrs_hae(x, y, z, precision \\ 5)
      when is_number(x) and is_number(y) and is_number(z) and is_integer(precision) do
    with {:ok, {lat, lon, hae}} <- to_latlon_hae(x, y, z),
         {:ok, mgrs} <- ExMgrs.latlon_to_mgrs(lat, lon, precision) do
      {:ok, {mgrs, hae}}
    end
  end

  @doc """
  Alias for `to_mgrs_hae/4`. The returned altitude is HAE (Height Above Ellipsoid).

  See `to_mgrs_hae/4` for full documentation.
  """
  def to_mgrs(x, y, z, precision \\ 5), do: to_mgrs_hae(x, y, z, precision)

  # ---------------------------------------------------------------------------
  # Distance
  # ---------------------------------------------------------------------------

  @doc """
  Computes the Euclidean distance in meters between two ECEF points.

  This is the straight-line distance through the Earth, not the surface distance.

  ## Parameters
  - `{x1, y1, z1}` - First point in ECEF meters
  - `{x2, y2, z2}` - Second point in ECEF meters

  ## Returns
  - Distance in meters

  ## Examples

      iex> Float.round(ExMgrs.Ecef.distance({6378137.0, 0.0, 0.0}, {6378137.0, 0.0, 0.0}), 1)
      0.0

  """
  def distance({x1, y1, z1}, {x2, y2, z2}) do
    dx = x2 - x1
    dy = y2 - y1
    dz = z2 - z1
    :math.sqrt(dx * dx + dy * dy + dz * dz)
  end
end
