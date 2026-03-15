defmodule ExMgrs.EcefTest do
  use ExUnit.Case
  doctest ExMgrs.Ecef

  describe "from_latlon_hae/3" do
    test "equator/prime meridian at ellipsoid surface" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(0.0, 0.0, 0.0)
      assert_in_delta x, 6_378_137.0, 0.01
      assert_in_delta y, 0.0, 0.01
      assert_in_delta z, 0.0, 0.01
    end

    test "north pole at ellipsoid surface" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(90.0, 0.0, 0.0)
      assert_in_delta x, 0.0, 0.01
      assert_in_delta y, 0.0, 0.01
      assert_in_delta z, 6_356_752.3142, 0.01
    end

    test "south pole at ellipsoid surface" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(-90.0, 0.0, 0.0)
      assert_in_delta x, 0.0, 0.01
      assert_in_delta y, 0.0, 0.01
      assert_in_delta z, -6_356_752.3142, 0.01
    end

    test "equator at 90 degrees east" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(0.0, 90.0, 0.0)
      assert_in_delta x, 0.0, 0.01
      assert_in_delta y, 6_378_137.0, 0.01
      assert_in_delta z, 0.0, 0.01
    end

    test "with HAE" do
      {:ok, {x, _y, _z}} = ExMgrs.Ecef.from_latlon_hae(0.0, 0.0, 1000.0)
      assert_in_delta x, 6_378_137.0 + 1000.0, 0.01
    end

    test "rejects invalid latitude" do
      assert {:error, _} = ExMgrs.Ecef.from_latlon_hae(91.0, 0.0)
      assert {:error, _} = ExMgrs.Ecef.from_latlon_hae(-91.0, 0.0)
    end

    test "rejects invalid longitude" do
      assert {:error, _} = ExMgrs.Ecef.from_latlon_hae(0.0, 181.0)
      assert {:error, _} = ExMgrs.Ecef.from_latlon_hae(0.0, -181.0)
    end

    test "defaults HAE to 0" do
      {:ok, result_no_hae} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24)
      {:ok, result_zero_hae} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 0.0)
      assert result_no_hae == result_zero_hae
    end
  end

  describe "from_latlon/3 alias" do
    test "matches from_latlon_hae with explicit hae" do
      {:ok, a} = ExMgrs.Ecef.from_latlon(34.0, -118.24, 500.0)
      {:ok, b} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 500.0)
      assert a == b
    end

    test "defaults alt to 0" do
      {:ok, a} = ExMgrs.Ecef.from_latlon(34.0, -118.24)
      {:ok, b} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 0.0)
      assert a == b
    end
  end

  describe "to_latlon_hae/3" do
    test "roundtrip at various locations" do
      locations = [
        {0.0, 0.0, 0.0},
        {34.0, -118.24, 0.0},
        {90.0, 0.0, 0.0},
        {-90.0, 0.0, 0.0},
        {51.5074, -0.1278, 11.0},
        {-33.8688, 151.2093, 58.0},
        {45.0, 45.0, 5000.0}
      ]

      for {lat, lon, hae} <- locations do
        {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(lat, lon, hae)
        {:ok, {lat2, lon2, hae2}} = ExMgrs.Ecef.to_latlon_hae(x, y, z)

        assert_in_delta lat2, lat, 1.0e-8, "lat roundtrip failed for {#{lat}, #{lon}, #{hae}}"

        assert_in_delta lon2, lon, 1.0e-8, "lon roundtrip failed for {#{lat}, #{lon}, #{hae}}"

        assert_in_delta hae2, hae, 0.001, "hae roundtrip failed for {#{lat}, #{lon}, #{hae}}"
      end
    end
  end

  describe "to_latlon/3 alias" do
    test "matches to_latlon_hae" do
      {:ok, a} = ExMgrs.Ecef.to_latlon(6_378_137.0, 0.0, 0.0)
      {:ok, b} = ExMgrs.Ecef.to_latlon_hae(6_378_137.0, 0.0, 0.0)
      assert a == b
    end
  end

  describe "from_mgrs_hae/2" do
    test "converts MGRS to ECEF" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_mgrs_hae("11SLT8548562848")
      assert is_float(x)
      assert is_float(y)
      assert is_float(z)
    end

    test "matches latlon path" do
      {:ok, {lat, lon}} = ExMgrs.mgrs_to_latlon("11SLT8548562848")
      {:ok, via_latlon} = ExMgrs.Ecef.from_latlon_hae(lat, lon, 500.0)
      {:ok, via_mgrs} = ExMgrs.Ecef.from_mgrs_hae("11SLT8548562848", 500.0)
      assert via_latlon == via_mgrs
    end

    test "defaults HAE to 0" do
      {:ok, a} = ExMgrs.Ecef.from_mgrs_hae("11SLT8548562848")
      {:ok, b} = ExMgrs.Ecef.from_mgrs_hae("11SLT8548562848", 0.0)
      assert a == b
    end

    test "rejects invalid MGRS" do
      assert {:error, _} = ExMgrs.Ecef.from_mgrs_hae("INVALID")
      assert {:error, _} = ExMgrs.Ecef.from_mgrs_hae("")
    end
  end

  describe "from_mgrs/2 alias" do
    test "matches from_mgrs_hae with explicit hae" do
      {:ok, a} = ExMgrs.Ecef.from_mgrs("11SLT8548562848", 100.0)
      {:ok, b} = ExMgrs.Ecef.from_mgrs_hae("11SLT8548562848", 100.0)
      assert a == b
    end

    test "defaults alt to 0" do
      {:ok, a} = ExMgrs.Ecef.from_mgrs("11SLT8548562848")
      {:ok, b} = ExMgrs.Ecef.from_mgrs_hae("11SLT8548562848", 0.0)
      assert a == b
    end
  end

  describe "to_mgrs_hae/4" do
    test "roundtrip through ECEF" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 0.0)
      {:ok, {mgrs, hae}} = ExMgrs.Ecef.to_mgrs_hae(x, y, z)
      assert String.starts_with?(mgrs, "11S")
      assert_in_delta hae, 0.0, 0.001
    end

    test "preserves HAE through roundtrip" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 750.0)
      {:ok, {_mgrs, hae}} = ExMgrs.Ecef.to_mgrs_hae(x, y, z)
      assert_in_delta hae, 750.0, 0.01
    end

    test "respects precision parameter" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 0.0)
      {:ok, {mgrs_3, _}} = ExMgrs.Ecef.to_mgrs_hae(x, y, z, 3)
      {:ok, {mgrs_5, _}} = ExMgrs.Ecef.to_mgrs_hae(x, y, z, 5)
      assert String.length(mgrs_3) < String.length(mgrs_5)
    end
  end

  describe "to_mgrs/4 alias" do
    test "matches to_mgrs_hae" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 0.0)
      {:ok, a} = ExMgrs.Ecef.to_mgrs(x, y, z)
      {:ok, b} = ExMgrs.Ecef.to_mgrs_hae(x, y, z)
      assert a == b
    end

    test "matches to_mgrs_hae with precision" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 0.0)
      {:ok, a} = ExMgrs.Ecef.to_mgrs(x, y, z, 3)
      {:ok, b} = ExMgrs.Ecef.to_mgrs_hae(x, y, z, 3)
      assert a == b
    end
  end

  describe "distance/2" do
    test "zero distance for same point" do
      point = {6_378_137.0, 0.0, 0.0}
      assert_in_delta ExMgrs.Ecef.distance(point, point), 0.0, 0.001
    end

    test "known distance along radial" do
      {:ok, p1} = ExMgrs.Ecef.from_latlon_hae(0.0, 0.0, 0.0)
      {:ok, p2} = ExMgrs.Ecef.from_latlon_hae(0.0, 0.0, 1000.0)
      assert_in_delta ExMgrs.Ecef.distance(p1, p2), 1000.0, 0.001
    end

    test "distance between two different locations" do
      {:ok, p1} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 0.0)
      {:ok, p2} = ExMgrs.Ecef.from_latlon_hae(40.7128, -74.0060, 0.0)
      dist = ExMgrs.Ecef.distance(p1, p2)
      # Straight-line ECEF distance NYC to LA should be roughly 3800-3900 km
      assert dist > 3_800_000
      assert dist < 3_970_000
    end
  end
end
