#!/usr/bin/env elixir

# Script to generate checksums for all precompiled NIFs

# Start required applications
:inets.start()
:ssl.start()

# Read version from mix.exs
version = File.read!("mix.exs")
  |> then(&Regex.run(~r/version: "([^"]+)"/, &1))
  |> List.last()

IO.puts("Generating checksums for version #{version}...\n")

base_url = "https://github.com/cortfritz/ex_mgrs/releases/download/v#{version}"

targets = [
  # macOS
  {"libgeoconvert_nif", "aarch64-apple-darwin", "so"},
  {"libgeoconvert_nif", "x86_64-apple-darwin", "so"},
  # Linux
  {"libgeoconvert_nif", "aarch64-unknown-linux-gnu", "so"},
  {"libgeoconvert_nif", "x86_64-unknown-linux-gnu", "so"},
  # Windows
  {"geoconvert_nif", "x86_64-pc-windows-gnu", "dll"},
  {"geoconvert_nif", "x86_64-pc-windows-msvc", "dll"}
]

nif_versions = ["2.15", "2.16", "2.17"]

checksums = for nif_version <- nif_versions,
                {name, target, ext} <- targets do
  filename = "#{name}-v#{version}-nif-#{nif_version}-#{target}.#{ext}.tar.gz"
  url = "#{base_url}/#{filename}"

  IO.puts("Downloading #{filename}...")

  case :httpc.request(:get, {String.to_charlist(url), []}, [{:ssl, verify: :verify_none}], [body_format: :binary]) do
    {:ok, {{_, 200, _}, _, body}} ->
      checksum = :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
      IO.puts("  ✓ #{checksum}")
      {filename, "sha256:#{checksum}"}
    {:ok, {{_, status, _}, _, _}} ->
      IO.puts("  ✗ HTTP #{status}")
      nil
    {:error, reason} ->
      IO.puts("  ✗ #{inspect(reason)}")
      nil
  end
end
|> Enum.reject(&is_nil/1)
|> Map.new()

# Write checksum file
File.write!("checksum-Elixir.ExMgrs.Native.exs", inspect(checksums, limit: :infinity, pretty: true) <> "\n")

IO.puts("\n✅ Generated checksum file with #{map_size(checksums)} entries")
