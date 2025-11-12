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
  def latlon_to_mgrs(lat, lon, precision \\ 5)
      when is_number(lat) and is_number(lon) and is_integer(precision) do
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

  @doc """
  Formats an MGRS string with proper spacing.

  Takes an MGRS string (with or without spaces) and returns it formatted with
  standard spacing: GZD + space + 100km Square + space + Easting + space + Northing

  ## Parameters
  - `mgrs`: MGRS coordinate string (with or without spaces)

  ## Returns
  - `{:ok, formatted_string}` on success
  - `{:error, reason}` if the MGRS string is invalid

  ## Examples

      iex> ExMgrs.format_mgrs("11SLT8548562848")
      {:ok, "11S LT 85485 62848"}

      iex> ExMgrs.format_mgrs("11S LT 85485 62848")
      {:ok, "11S LT 85485 62848"}

      iex> ExMgrs.format_mgrs("11SLT854628")
      {:ok, "11S LT 854 628"}

  """
  def format_mgrs(mgrs) when is_binary(mgrs) do
    # Remove all whitespace
    clean = String.replace(mgrs, ~r/\s+/, "")

    parse_mgrs(clean)
  end

  # Try 2-digit zone first
  defp parse_mgrs(<<z1, z2, band, s1, s2, rest::binary>>)
       when z1 in ?0..?9 and z2 in ?0..?9 and
              band in ?C..?X and
              s1 in ?A..?Z and s2 in ?A..?Z do
    validate_and_format(<<z1, z2>>, <<band>>, <<s1, s2>>, rest)
  end

  # Try 1-digit zone
  defp parse_mgrs(<<z1, band, s1, s2, rest::binary>>)
       when z1 in ?0..?9 and
              band in ?C..?X and
              s1 in ?A..?Z and s2 in ?A..?Z do
    validate_and_format(<<z1>>, <<band>>, <<s1, s2>>, rest)
  end

  defp parse_mgrs(_), do: {:error, "Invalid MGRS format"}

  defp validate_and_format(zone, band, square, digits) do
    digit_count = byte_size(digits)

    cond do
      digit_count > 10 ->
        {:error, "Invalid MGRS: too many digits (max 10)"}

      rem(digit_count, 2) != 0 ->
        {:error, "Invalid MGRS: easting and northing must have equal precision"}

      digit_count == 0 ->
        {:ok, "#{zone}#{band} #{square}"}

      true ->
        precision = div(digit_count, 2)
        <<easting::binary-size(precision), northing::binary-size(precision)>> = digits
        {:ok, "#{zone}#{band} #{square} #{easting} #{northing}"}
    end
  end
end
