defmodule Membrane.FFmpeg.VideoFilter.Mixfile do
  use Mix.Project

  @version "0.13.1"
  @github_url "https://github.com/membraneframework/membrane_ffmpeg_video_filter_plugin"

  def project do
    [
      app: :membrane_ffmpeg_video_filter_plugin,
      version: @version,
      elixir: "~> 1.12",
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      diayzer: dialyzer(),
      description:
        "Plugin for applying video filters using [FFmpeg](https://www.ffmpeg.org/) library",
      package: package(),
      name: "Membrane FFmpeg Video Filter plugin",
      source_url: @github_url,
      homepage_url: "https://membraneframework.org",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:membrane_core, "~> 1.0"},
      {:membrane_raw_video_format, "~> 0.3.0"},
      {:membrane_common_c, "~> 0.16.0"},
      {:unifex, "~> 1.0"},
      {:bundlex, "~> 1.2"},
      {:membrane_precompiled_dependency_provider, "~> 0.1.0"},
      # Testing
      {:membrane_file_plugin, "~> 0.13", only: :test},
      {:membrane_h264_ffmpeg_plugin, "~> 0.31.0", only: :test},
      {:membrane_h264_plugin, "~> 0.9.0", only: :test},
      # Development
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      },
      files: ["lib", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs", "c_src"],
      exclude_patterns: [~r"c_src/.*/_generated.*"]
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp aliases do
    [docs: ["docs", &copy_images/1]]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.FFmpeg.VideoFilter]
    ]
  end

  defp copy_images(_) do
    File.cp_r("readme", "doc/readme", fn source, destination ->
      IO.gets("Overwriting #{destination} by #{source}. Type y to confirm. ") == "y\n"
    end)
  end
end
