import Config

# Force local builds during development since precompiled binaries
# may not exist for unreleased versions
config :rustler_precompiled, :force_build, ex_mgrs: true

if Mix.env() == :dev do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_push: [
        tasks: [
          {:cmd, "mix", ["test"]},
          {:cmd, "mix", ["format", "--check-formatted"]}
        ]
      ]
    ]
end
