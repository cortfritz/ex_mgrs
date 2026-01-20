import Config

# Force local builds during development since precompiled binaries
# may not exist for unreleased versions
config :rustler_precompiled, :force_build, ex_mgrs: true
