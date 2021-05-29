defmodule Unsub.MixProject do
  use Mix.Project

  def project do
    [
      app: :unsub,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Unsub, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      {:plug_cowboy, "~> 1.0"},
      # {:stripity_stripe, "~> 2.0.0"},
      {:stripity_stripe, git: "https://github.com/code-corps/stripity_stripe"},
      {:bamboo_smtp, "~> 1.4.0"}
    ]
  end
end
