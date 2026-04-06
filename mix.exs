defmodule OpenCC.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jkwchui/opencc_ex"

  def project do
    [
      app: :opencc,
      version: "0.1.0",
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
      {:rustler, "~> 0.37", optional: true},
      {:rustler_precompiled, "0.9.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: [
        "lib",
        "native/opencc_nif/src",
        "native/opencc_nif/Cargo.toml",
        "native/opencc_nif/Cargo.lock",
        "native/opencc_nif/.cargo",
        "checksum.exs",
        "mix.exs",
        "README.md"
      ]
    ]
  end
end
