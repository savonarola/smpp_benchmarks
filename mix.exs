defmodule SmppBenchmarks.Mixfile do
  use Mix.Project

  def project do
    [app: :smpp_benchmarks,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :smppex]]
  end


  defp deps do
    [
      {:oserl, git: "https://github.com/funbox/oserl.git", branch: "v4", only: :dev},
      {:smppex, "~> 0.1.0", only: :dev},
    ]
  end
end
