defmodule ExMgrs.Native do
  use Rustler, otp_app: :ex_mgrs, crate: "geoconvert_nif"

  # When your NIF is loaded, it will override this function.
  def latlon_to_mgrs_nif(_lat, _lon, _precision), do: :erlang.nif_error(:nif_not_loaded)

  def mgrs_to_latlon_nif(_mgrs), do: :erlang.nif_error(:nif_not_loaded)
end
