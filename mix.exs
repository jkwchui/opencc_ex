defmodule OpenCC.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/jkwchui/opencc_ex"

  def project do
    [
      app: :opencc,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Simplified-Traditional Chinese conversion, via ferrous-opencc Rust crate as NIF",
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
      {:nimble_pool, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:rustler, "~> 0.30", optional: true},
      {:rustler_precompiled, "~> 0.7"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: [
        "lib",
        "native/opencc/src",
        "native/opencc/Cargo.toml",
        "native/opencc/Cargo.lock",
        "mix.exs",
        "README.md",
        "checksum-Elixir.OpenCC.Native.exs"
      ]
    ]
  end
end
