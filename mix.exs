defmodule ExMgrs.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_mgrs,
      version: "0.0.6",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.36", runtime: false},
      {:rustler_precompiled, "~> 0.8"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Elixir library for converting between latitude/longitude coordinates and MGRS (Military Grid Reference System) coordinates using embedded Rust geoconvert library."
  end

  defp package do
    [
      name: "ex_mgrs",
      files: [
        "lib",
        "native/geoconvert_nif/src",
        "native/geoconvert_nif/Cargo.toml",
        "native/geoconvert_embedded",
        "priv/native",
        "checksum-*.exs",
        "mix.exs",
        "README.md",
        "LICENSE*"
      ],
      maintainers: ["Cort Fritz"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/cortfritz/ex_mgrs"}
    ]
  end
end
