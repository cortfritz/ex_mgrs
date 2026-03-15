defmodule ExMgrs.GeoidTest do
  use ExUnit.Case
  doctest ExMgrs.Geoid

  describe "undulation/2" do
    test "returns known undulation at 0,0 (Gulf of Guinea)" do
      {:ok, n} = ExMgrs.Geoid.undulation(0.0, 0.0)
      # EGM96 undulation near 0,0 is approximately 17m
      assert_in_delta n, 17.16, 1.0
    end

    test "returns negative undulation in Indian Ocean" do
      # The Indian Ocean geoid low is the deepest depression
      {:ok, n} = ExMgrs.Geoid.undulation(5.0, 78.0)
      assert n < -50.0
    end

    test "returns positive undulation in North Atlantic" do
      # Iceland / North Atlantic has a geoid high
      {:ok, n} = ExMgrs.Geoid.undulation(65.0, -20.0)
      assert n > 40.0
    end

    test "handles poles" do
      {:ok, north} = ExMgrs.Geoid.undulation(90.0, 0.0)
      assert is_float(north)

      {:ok, south} = ExMgrs.Geoid.undulation(-90.0, 0.0)
      assert is_float(south)
    end

    test "handles antimeridian" do
      {:ok, n1} = ExMgrs.Geoid.undulation(0.0, 180.0)
      {:ok, n2} = ExMgrs.Geoid.undulation(0.0, -180.0)
      assert_in_delta n1, n2, 0.01
    end

    test "rejects invalid latitude" do
      assert {:error, _} = ExMgrs.Geoid.undulation(91.0, 0.0)
      assert {:error, _} = ExMgrs.Geoid.undulation(-91.0, 0.0)
    end

    test "rejects invalid longitude" do
      assert {:error, _} = ExMgrs.Geoid.undulation(0.0, 181.0)
      assert {:error, _} = ExMgrs.Geoid.undulation(0.0, -181.0)
    end
  end

  describe "hae_to_msl/3" do
    test "roundtrip with msl_to_hae" do
      lat = 34.0
      lon = -118.24
      hae = 500.0

      {:ok, msl} = ExMgrs.Geoid.hae_to_msl(lat, lon, hae)
      {:ok, hae_back} = ExMgrs.Geoid.msl_to_hae(lat, lon, msl)

      assert_in_delta hae_back, hae, 0.001
    end

    test "MSL differs from HAE" do
      {:ok, msl} = ExMgrs.Geoid.hae_to_msl(0.0, 0.0, 100.0)
      # At 0,0 undulation is ~17m, so MSL should be ~83m
      assert msl < 100.0
      assert msl > 50.0
    end

    test "rejects invalid coordinates" do
      assert {:error, _} = ExMgrs.Geoid.hae_to_msl(91.0, 0.0, 100.0)
      assert {:error, _} = ExMgrs.Geoid.hae_to_msl(0.0, 181.0, 100.0)
    end
  end

  describe "msl_to_hae/3" do
    test "rejects invalid coordinates" do
      assert {:error, _} = ExMgrs.Geoid.msl_to_hae(91.0, 0.0, 100.0)
      assert {:error, _} = ExMgrs.Geoid.msl_to_hae(0.0, 181.0, 100.0)
    end

    test "adds positive undulation" do
      {:ok, hae} = ExMgrs.Geoid.msl_to_hae(0.0, 0.0, 100.0)
      # At 0,0 undulation is ~17m, so HAE should be ~117m
      assert hae > 100.0
    end
  end

  describe "alt_to_msl/3 and msl_to_alt/3 aliases" do
    test "alt_to_msl matches hae_to_msl" do
      {:ok, a} = ExMgrs.Geoid.alt_to_msl(34.0, -118.24, 500.0)
      {:ok, b} = ExMgrs.Geoid.hae_to_msl(34.0, -118.24, 500.0)
      assert a == b
    end

    test "msl_to_alt matches msl_to_hae" do
      {:ok, a} = ExMgrs.Geoid.msl_to_alt(34.0, -118.24, 500.0)
      {:ok, b} = ExMgrs.Geoid.msl_to_hae(34.0, -118.24, 500.0)
      assert a == b
    end
  end

  describe "latlon_msl_to_ecef/3" do
    test "differs from HAE-based ECEF" do
      lat = 0.0
      lon = 0.0
      height = 100.0

      {:ok, {x_hae, _, _}} = ExMgrs.Ecef.from_latlon_hae(lat, lon, height)
      {:ok, {x_msl, _, _}} = ExMgrs.Geoid.latlon_msl_to_ecef(lat, lon, height)

      # At 0,0, undulation is ~17m, so MSL-based should be ~17m further from center
      assert x_msl > x_hae
      assert_in_delta x_msl - x_hae, 17.16, 1.0
    end

    test "roundtrip through ecef_to_latlon_msl" do
      lat = 34.0
      lon = -118.24
      msl = 500.0

      {:ok, {x, y, z}} = ExMgrs.Geoid.latlon_msl_to_ecef(lat, lon, msl)
      {:ok, {lat2, lon2, msl2}} = ExMgrs.Geoid.ecef_to_latlon_msl(x, y, z)

      assert_in_delta lat2, lat, 1.0e-8
      assert_in_delta lon2, lon, 1.0e-8
      assert_in_delta msl2, msl, 0.01
    end

    test "defaults MSL to 0" do
      {:ok, a} = ExMgrs.Geoid.latlon_msl_to_ecef(34.0, -118.24)
      {:ok, b} = ExMgrs.Geoid.latlon_msl_to_ecef(34.0, -118.24, 0.0)
      assert a == b
    end

    test "rejects invalid coordinates" do
      assert {:error, _} = ExMgrs.Geoid.latlon_msl_to_ecef(91.0, 0.0, 0.0)
      assert {:error, _} = ExMgrs.Geoid.latlon_msl_to_ecef(0.0, 181.0, 0.0)
    end
  end

  describe "ecef_to_latlon_msl/3" do
    test "converts ECEF point to lat/lon/msl" do
      # Point 100m above ellipsoid at equator/prime meridian
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(0.0, 0.0, 100.0)
      {:ok, {lat, lon, msl}} = ExMgrs.Geoid.ecef_to_latlon_msl(x, y, z)

      assert_in_delta lat, 0.0, 0.001
      assert_in_delta lon, 0.0, 0.001
      # MSL should be less than 100m due to positive undulation at 0,0
      assert msl < 100.0
    end

    test "returns known MSL for known ECEF at LA" do
      # 500m HAE at LA
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 500.0)
      {:ok, {lat, lon, msl}} = ExMgrs.Geoid.ecef_to_latlon_msl(x, y, z)

      assert_in_delta lat, 34.0, 1.0e-6
      assert_in_delta lon, -118.24, 1.0e-6
      # LA undulation is ~-33m, so MSL should be ~533m
      assert msl > 500.0
    end
  end

  describe "mgrs_msl_to_ecef/2" do
    test "converts MGRS + MSL to ECEF" do
      {:ok, {x, y, z}} = ExMgrs.Geoid.mgrs_msl_to_ecef("11SLT8548562848", 500.0)
      assert is_float(x)
      assert is_float(y)
      assert is_float(z)
    end

    test "differs from HAE-based ECEF" do
      mgrs = "11SLT8548562848"
      height = 500.0

      {:ok, {x_hae, _, _}} = ExMgrs.Ecef.from_mgrs_hae(mgrs, height)
      {:ok, {x_msl, _, _}} = ExMgrs.Geoid.mgrs_msl_to_ecef(mgrs, height)

      # LA area undulation is roughly -33m, so MSL 500 -> HAE ~467 -> closer to center
      assert x_msl != x_hae
    end

    test "defaults MSL to 0" do
      {:ok, a} = ExMgrs.Geoid.mgrs_msl_to_ecef("11SLT8548562848")
      {:ok, b} = ExMgrs.Geoid.mgrs_msl_to_ecef("11SLT8548562848", 0.0)
      assert a == b
    end

    test "rejects invalid MGRS" do
      assert {:error, _} = ExMgrs.Geoid.mgrs_msl_to_ecef("INVALID")
      assert {:error, _} = ExMgrs.Geoid.mgrs_msl_to_ecef("")
    end
  end

  describe "ecef_to_mgrs_msl/4" do
    test "roundtrip through mgrs_msl_to_ecef" do
      mgrs_in = "11SLT8548562848"
      msl_in = 500.0

      {:ok, {x, y, z}} = ExMgrs.Geoid.mgrs_msl_to_ecef(mgrs_in, msl_in)
      {:ok, {mgrs_out, msl_out}} = ExMgrs.Geoid.ecef_to_mgrs_msl(x, y, z)

      assert mgrs_out == mgrs_in
      assert_in_delta msl_out, msl_in, 0.01
    end

    test "respects precision parameter" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 100.0)
      {:ok, {mgrs_3, _}} = ExMgrs.Geoid.ecef_to_mgrs_msl(x, y, z, 3)
      {:ok, {mgrs_5, _}} = ExMgrs.Geoid.ecef_to_mgrs_msl(x, y, z, 5)
      assert String.length(mgrs_3) < String.length(mgrs_5)
    end

    test "defaults precision to 5" do
      {:ok, {x, y, z}} = ExMgrs.Ecef.from_latlon_hae(34.0, -118.24, 100.0)
      {:ok, a} = ExMgrs.Geoid.ecef_to_mgrs_msl(x, y, z)
      {:ok, b} = ExMgrs.Geoid.ecef_to_mgrs_msl(x, y, z, 5)
      assert a == b
    end
  end

  describe "mgrs_hae_to_msl/2" do
    test "converts MGRS + HAE to lat/lon/MSL" do
      {:ok, {lat, lon, msl}} = ExMgrs.Geoid.mgrs_hae_to_msl("11SLT8548562848", 500.0)

      assert_in_delta lat, 34.0, 0.01
      assert_in_delta lon, -118.24, 0.01
      assert is_float(msl)
      # LA area undulation is roughly -33m, so MSL should be ~533m
      assert msl > 500.0
    end

    test "defaults to 0 HAE" do
      {:ok, {_lat, _lon, msl}} = ExMgrs.Geoid.mgrs_hae_to_msl("11SLT8548562848")
      {:ok, n} = ExMgrs.Geoid.undulation(34.0, -118.24)
      # msl should be approximately -N (since HAE=0)
      assert_in_delta msl, -n, 1.0
    end

    test "rejects invalid MGRS" do
      assert {:error, _} = ExMgrs.Geoid.mgrs_hae_to_msl("INVALID", 100.0)
      assert {:error, _} = ExMgrs.Geoid.mgrs_hae_to_msl("")
    end
  end

  describe "mgrs_alt_to_msl/2 alias" do
    test "matches mgrs_hae_to_msl with explicit hae" do
      {:ok, a} = ExMgrs.Geoid.mgrs_alt_to_msl("11SLT8548562848", 500.0)
      {:ok, b} = ExMgrs.Geoid.mgrs_hae_to_msl("11SLT8548562848", 500.0)
      assert a == b
    end

    test "defaults alt to 0" do
      {:ok, a} = ExMgrs.Geoid.mgrs_alt_to_msl("11SLT8548562848")
      {:ok, b} = ExMgrs.Geoid.mgrs_hae_to_msl("11SLT8548562848", 0.0)
      assert a == b
    end
  end

  describe "mgrs_msl_to_hae/2" do
    test "roundtrip with mgrs_hae_to_msl" do
      mgrs = "11SLT8548562848"
      hae = 500.0

      {:ok, {_, _, msl}} = ExMgrs.Geoid.mgrs_hae_to_msl(mgrs, hae)
      {:ok, {_, _, hae_back}} = ExMgrs.Geoid.mgrs_msl_to_hae(mgrs, msl)

      assert_in_delta hae_back, hae, 0.001
    end

    test "defaults MSL to 0" do
      {:ok, a} = ExMgrs.Geoid.mgrs_msl_to_hae("11SLT8548562848")
      {:ok, b} = ExMgrs.Geoid.mgrs_msl_to_hae("11SLT8548562848", 0.0)
      assert a == b
    end

    test "rejects invalid MGRS" do
      assert {:error, _} = ExMgrs.Geoid.mgrs_msl_to_hae("INVALID", 100.0)
      assert {:error, _} = ExMgrs.Geoid.mgrs_msl_to_hae("")
    end
  end

  describe "mgrs_msl_to_alt/2 alias" do
    test "matches mgrs_msl_to_hae with explicit msl" do
      {:ok, a} = ExMgrs.Geoid.mgrs_msl_to_alt("11SLT8548562848", 500.0)
      {:ok, b} = ExMgrs.Geoid.mgrs_msl_to_hae("11SLT8548562848", 500.0)
      assert a == b
    end

    test "defaults msl to 0" do
      {:ok, a} = ExMgrs.Geoid.mgrs_msl_to_alt("11SLT8548562848")
      {:ok, b} = ExMgrs.Geoid.mgrs_msl_to_hae("11SLT8548562848", 0.0)
      assert a == b
    end
  end

  describe "deprecated aliases" do
    test "ellipsoid_to_msl delegates to hae_to_msl" do
      {:ok, a} = ExMgrs.Geoid.ellipsoid_to_msl(0.0, 0.0, 100.0)
      {:ok, b} = ExMgrs.Geoid.hae_to_msl(0.0, 0.0, 100.0)
      assert a == b
    end

    test "msl_to_ellipsoid delegates to msl_to_hae" do
      {:ok, a} = ExMgrs.Geoid.msl_to_ellipsoid(0.0, 0.0, 100.0)
      {:ok, b} = ExMgrs.Geoid.msl_to_hae(0.0, 0.0, 100.0)
      assert a == b
    end

    test "ecef_to_msl delegates to ecef_to_latlon_msl" do
      {:ok, a} = ExMgrs.Geoid.ecef_to_msl(6_378_237.0, 0.0, 0.0)
      {:ok, b} = ExMgrs.Geoid.ecef_to_latlon_msl(6_378_237.0, 0.0, 0.0)
      assert a == b
    end

    test "mgrs_to_msl delegates to mgrs_hae_to_msl" do
      {:ok, a} = ExMgrs.Geoid.mgrs_to_msl("11SLT8548562848", 100.0)
      {:ok, b} = ExMgrs.Geoid.mgrs_hae_to_msl("11SLT8548562848", 100.0)
      assert a == b
    end

    test "mgrs_to_msl defaults to 0" do
      {:ok, a} = ExMgrs.Geoid.mgrs_to_msl("11SLT8548562848")
      {:ok, b} = ExMgrs.Geoid.mgrs_hae_to_msl("11SLT8548562848", 0.0)
      assert a == b
    end

    test "msl_to_ecef delegates to latlon_msl_to_ecef" do
      {:ok, a} = ExMgrs.Geoid.msl_to_ecef(0.0, 0.0, 100.0)
      {:ok, b} = ExMgrs.Geoid.latlon_msl_to_ecef(0.0, 0.0, 100.0)
      assert a == b
    end

    test "msl_to_ecef defaults to 0" do
      {:ok, a} = ExMgrs.Geoid.msl_to_ecef(0.0, 0.0)
      {:ok, b} = ExMgrs.Geoid.latlon_msl_to_ecef(0.0, 0.0, 0.0)
      assert a == b
    end
  end
end
