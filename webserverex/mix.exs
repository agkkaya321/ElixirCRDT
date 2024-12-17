defmodule Webserverex.MixProject do
  use Mix.Project

  def project do
    [
      app: :webserverex,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration de l'application
  def application do
    [
      extra_applications: [:logger],
      mod: {Webserverex.Application, []}
    ]
  end

  # Dépendances
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
