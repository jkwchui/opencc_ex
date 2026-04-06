defmodule OpenCC.Native do
  @moduledoc false

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :opencc,
    crate: "opencc",
    base_url: "https://github.com/jkwchui/opencc_ex/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_PRECOMPILATION_EXAMPLE_BUILD") in ["1", "true"],
    version: version,
    targets: [
      "aarch64-apple-darwin",
      "x86_64-unknown-linux-gnu",
      "x86_64-pc-windows-gnu",
      "x86_64-pc-windows-msvc"
    ]

  def new_builtin(_config), do: :erlang.nif_error(:nif_not_loaded)
  def new_custom(_path), do: :erlang.nif_error(:nif_not_loaded)
  def convert(_ref, _text), do: :erlang.nif_error(:nif_not_loaded)
end
