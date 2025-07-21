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
        tolerance = case precision do
          1 -> 10000.0    # 10km
          2 -> 1000.0     # 1km  
          3 -> 100.0      # 100m
          4 -> 10.0       # 10m
          5 -> 1.0        # 1m
        end
        
        # Convert to meters for distance comparison (rough approximation)
        lat_diff_m = abs(converted_lat - lat) * 111000  # ~111km per degree lat
        lon_diff_m = abs(converted_lon - lon) * 111000 * :math.cos(lat * :math.pi / 180)
        
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
      assert {:error, _} = ExMgrs.latlon_to_mgrs(91.0, 0.0)    # lat > 90
      assert {:error, _} = ExMgrs.latlon_to_mgrs(-91.0, 0.0)   # lat < -90  
      assert {:error, _} = ExMgrs.latlon_to_mgrs(0.0, 181.0)   # lon > 180
      assert {:error, _} = ExMgrs.latlon_to_mgrs(0.0, -181.0)  # lon < -180
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
end
