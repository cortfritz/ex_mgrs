defmodule ExMgrsTest do
  use ExUnit.Case
  doctest ExMgrs

  describe "coordinate conversion" do
    test "converts lat/lon to MGRS" do
      assert {:ok, mgrs} = ExMgrs.latlon_to_mgrs(34.0, -118.24)
      assert is_binary(mgrs)
      assert String.length(mgrs) > 0
    end

    test "converts MGRS to lat/lon" do
      {:ok, mgrs} = ExMgrs.latlon_to_mgrs(34.0, -118.24)
      assert {:ok, {lat, lon}} = ExMgrs.mgrs_to_latlon(mgrs)
      assert is_float(lat)
      assert is_float(lon)
    end

    test "roundtrip conversion with specific coordinates" do
      original_lat = 34.0
      original_lon = -118.24

      # Convert to MGRS
      assert {:ok, mgrs} = ExMgrs.latlon_to_mgrs(original_lat, original_lon)

      # Convert back to lat/lon
      assert {:ok, {converted_lat, converted_lon}} = ExMgrs.mgrs_to_latlon(mgrs)

      # Check that we get back approximately the same coordinates
      # Allow for small floating point precision differences
      assert abs(converted_lat - original_lat) < 0.001
      assert abs(converted_lon - original_lon) < 0.001
    end

    test "roundtrip conversion in reverse direction" do
      # Start with a known MGRS coordinate
      {:ok, mgrs} = ExMgrs.latlon_to_mgrs(34.0, -118.24)

      # Convert to lat/lon
      assert {:ok, {lat, lon}} = ExMgrs.mgrs_to_latlon(mgrs)

      # Convert back to MGRS
      assert {:ok, converted_mgrs} = ExMgrs.latlon_to_mgrs(lat, lon)

      # The MGRS strings should be the same (or very close depending on precision)
      assert mgrs == converted_mgrs
    end

    test "handles different precision levels" do
      lat = 34.0
      lon = -118.24

      # Test with different precisions
      for precision <- 1..5 do
        assert {:ok, mgrs} = ExMgrs.latlon_to_mgrs(lat, lon, precision)
        assert is_binary(mgrs)

        # Convert back
        assert {:ok, {converted_lat, converted_lon}} = ExMgrs.mgrs_to_latlon(mgrs)

        # Higher precision should give more accurate results
        tolerance =
          case precision do
            # 10km
            1 -> 10000.0
            # 1km  
            2 -> 1000.0
            # 100m
            3 -> 100.0
            # 10m
            4 -> 10.0
            # 1m
            5 -> 1.0
          end

        # Convert to meters for distance comparison (rough approximation)
        # ~111km per degree lat
        lat_diff_m = abs(converted_lat - lat) * 111_000
        lon_diff_m = abs(converted_lon - lon) * 111_000 * :math.cos(lat * :math.pi() / 180)

        assert lat_diff_m < tolerance
        assert lon_diff_m < tolerance
      end
    end

    test "handles invalid MGRS strings" do
      assert {:error, _} = ExMgrs.mgrs_to_latlon("invalid_mgrs")
      assert {:error, _} = ExMgrs.mgrs_to_latlon("")
      assert {:error, _} = ExMgrs.mgrs_to_latlon("12345")
    end

    test "handles invalid lat/lon coordinates" do
      # Test coordinates outside valid ranges
      # lat > 90
      assert {:error, _} = ExMgrs.latlon_to_mgrs(91.0, 0.0)
      # lat < -90  
      assert {:error, _} = ExMgrs.latlon_to_mgrs(-91.0, 0.0)
      # lon > 180
      assert {:error, _} = ExMgrs.latlon_to_mgrs(0.0, 181.0)
      # lon < -180
      assert {:error, _} = ExMgrs.latlon_to_mgrs(0.0, -181.0)
    end
  end

  describe "specific test coordinates" do
    test "converts 34.0, -118.24 correctly" do
      lat = 34.0
      lon = -118.24

      # Convert to MGRS
      assert {:ok, mgrs} = ExMgrs.latlon_to_mgrs(lat, lon)

      # The expected MGRS for these coordinates should be something like "11SMS..."
      assert String.starts_with?(mgrs, "11S")

      # Convert back and verify roundtrip
      assert {:ok, {converted_lat, converted_lon}} = ExMgrs.mgrs_to_latlon(mgrs)

      assert_in_delta(converted_lat, lat, 0.001)
      assert_in_delta(converted_lon, lon, 0.001)
    end
  end

  describe "format_mgrs/1" do
    test "formats unspaced MGRS string with precision 5" do
      assert {:ok, "11S LT 85485 62848"} = ExMgrs.format_mgrs("11SLT8548562848")
    end

    test "formats already spaced MGRS string" do
      assert {:ok, "11S LT 85485 62848"} = ExMgrs.format_mgrs("11S LT 85485 62848")
    end

    test "formats MGRS with different precision levels" do
      assert {:ok, "11S LT 8 6"} = ExMgrs.format_mgrs("11SLT86")
      assert {:ok, "11S LT 85 62"} = ExMgrs.format_mgrs("11SLT8562")
      assert {:ok, "11S LT 854 628"} = ExMgrs.format_mgrs("11SLT854628")
      assert {:ok, "11S LT 8548 6284"} = ExMgrs.format_mgrs("11SLT85486284")
      assert {:ok, "11S LT 85485 62848"} = ExMgrs.format_mgrs("11SLT8548562848")
    end

    test "formats MGRS with single-digit zone" do
      assert {:ok, "1S AB 12345 67890"} = ExMgrs.format_mgrs("1SAB1234567890")
    end

    test "formats MGRS with no easting/northing (100km square center)" do
      assert {:ok, "11S LT"} = ExMgrs.format_mgrs("11SLT")
    end

    test "handles various whitespace formats" do
      assert {:ok, "11S LT 85485 62848"} = ExMgrs.format_mgrs("11S  LT  85485  62848")
      assert {:ok, "11S LT 85485 62848"} = ExMgrs.format_mgrs("11SLT 85485 62848")
      assert {:ok, "11S LT 85485 62848"} = ExMgrs.format_mgrs("11S LT85485 62848")
    end

    test "rejects invalid MGRS format" do
      assert {:error, "Invalid MGRS format"} = ExMgrs.format_mgrs("invalid")
      assert {:error, "Invalid MGRS format"} = ExMgrs.format_mgrs("123")
      assert {:error, "Invalid MGRS format"} = ExMgrs.format_mgrs("11A12")
    end

    test "rejects odd number of digits" do
      assert {:error, "Invalid MGRS: easting and northing must have equal precision"} =
               ExMgrs.format_mgrs("11SLT123")
    end

    test "rejects too many digits" do
      assert {:error, "Invalid MGRS: too many digits (max 10)"} =
               ExMgrs.format_mgrs("11SLT12345678901")
    end

    test "validates latitude band letters (C-X)" do
      # Valid bands
      assert {:ok, "11C LT 12345 67890"} = ExMgrs.format_mgrs("11CLT1234567890")
      assert {:ok, "11X LT 12345 67890"} = ExMgrs.format_mgrs("11XLT1234567890")

      # Invalid bands (A, B, Y, Z not valid in MGRS)
      assert {:error, "Invalid MGRS format"} = ExMgrs.format_mgrs("11ALT1234567890")
      assert {:error, "Invalid MGRS format"} = ExMgrs.format_mgrs("11ZLT1234567890")
    end

    test "roundtrip with format_mgrs" do
      {:ok, mgrs} = ExMgrs.latlon_to_mgrs(34.0, -118.24, 5)
      assert {:ok, formatted} = ExMgrs.format_mgrs(mgrs)
      # Should be able to re-format the formatted version (removes spaces)
      assert {:ok, reformatted} = ExMgrs.format_mgrs(formatted)
      assert reformatted == formatted
      # To use with NIF, need to remove spaces
      unspaced = String.replace(formatted, " ", "")
      assert {:ok, {_lat, _lon}} = ExMgrs.mgrs_to_latlon(unspaced)
    end
  end
end
