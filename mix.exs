defmodule WamekuServerScratch.Mixfile do
  use Mix.Project

  def project do
    [app: :wameku_server_scratch,
      version: "0.0.1",
      elixir: "~> 1.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :calendar, :amnesia, :porcelain],
      mod: {WamekuServerScratch, []}]
  end

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
      {:poison, "~> 1.5"},
      {:porcelain, "~> 2.0"},
      {:amnesia, "~> 0.2.1"},
      {:calendar, "~> 0.14"},
      {:amqp, "~> 0.1.4"}
    ]
  end
end
