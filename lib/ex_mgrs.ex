defmodule ExMgrs do
  @moduledoc """
  A library for converting between latitude/longitude coordinates and MGRS (Military Grid Reference System) coordinates.
  
  This module provides functions to convert between decimal degree coordinates (latitude/longitude)
  and MGRS coordinate strings using the WGS84 ellipsoid.
  """

  alias ExMgrs.Native

  @doc """
  Converts latitude/longitude coordinates to MGRS format.

  ## Parameters
  - `lat`: Latitude in decimal degrees (-90.0 to 90.0)
  - `lon`: Longitude in decimal degrees (-180.0 to 180.0)  
  - `precision`: Number of digits for easting/northing (1-5, default: 5)

  ## Returns
  - `{:ok, mgrs_string}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> ExMgrs.latlon_to_mgrs(34.0, -118.24)
      {:ok, "11SLT8548562848"}

  """
  def latlon_to_mgrs(lat, lon, precision \\ 5) when is_number(lat) and is_number(lon) and is_integer(precision) do
    Native.latlon_to_mgrs_nif(lat, lon, precision)
  end

  @doc """
  Converts MGRS coordinates to latitude/longitude format.

  ## Parameters
  - `mgrs`: MGRS coordinate string

  ## Returns
  - `{:ok, {latitude, longitude}}` on success where coordinates are in decimal degrees
  - `{:error, {0.0, 0.0}}` on failure

  ## Examples

      iex> {:ok, {lat, lon}} = ExMgrs.mgrs_to_latlon("11SLT8548562848")
      ...> {Float.round(lat, 5), Float.round(lon, 5)}
      {34.0, -118.24}

  """
  def mgrs_to_latlon(mgrs) when is_binary(mgrs) do
    Native.mgrs_to_latlon_nif(mgrs)
  end
end
