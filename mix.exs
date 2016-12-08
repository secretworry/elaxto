defmodule Elaxto.Mixfile do
  use Mix.Project

  def project do
    [app: :elaxto,
     version: "0.1.0",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: applications ++ [:poison, :ibrowse]
  defp applications, do: [:logger]

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:maxwell, git: "https://github.com/zhongwencool/maxwell.git", tag: "2.0.0", only: [:dev, :test]},
      {:ibrowse, "~> 4.2", only: [:dev, :test]},
      {:poison, "~> 2.1", only: [:dev, :test]}
    ]
  end
end
