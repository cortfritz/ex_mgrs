defmodule ExMgrs.Native do
  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :ex_mgrs,
    crate: "geoconvert_nif",
    base_url: "https://github.com/cortfritz/ex_mgrs/releases/download/v#{version}",
    force_build:
      System.get_env("RUSTLER_PRECOMPILATION_EXAMPLE_BUILD") in ["1", "true"] or
        Mix.env() in [:dev, :test],
    version: version

  # When your NIF is loaded, it will override this function.
  def latlon_to_mgrs_nif(_lat, _lon, _precision), do: :erlang.nif_error(:nif_not_loaded)

  def mgrs_to_latlon_nif(_mgrs), do: :erlang.nif_error(:nif_not_loaded)
end
