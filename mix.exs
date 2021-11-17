defmodule Membrane.FFmpeg.VideoFilter.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/membraneframework/membrane_ffmpeg_video_filter_plugin"

  def project do
    [
      app: :membrane_ffmpeg_video_filter_plugin,
      version: @version,
      elixir: "~> 1.12",
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description:
        "Plugin for applying video filters using [FFmpeg](https://www.ffmpeg.org/) library",
      package: package(),

      # docs
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
      {:membrane_core, "~> 0.7.0"},
      {:membrane_caps_video_raw, "~> 0.1.0"},
      {:membrane_common_c, "~> 0.9.0"},
      {:unifex, "~> 0.7.0"},
      {:membrane_file_plugin, "~> 0.6.0", only: [:dev, :test]},
      {:membrane_h264_ffmpeg_plugin, "~> 0.12.0", only: [:dev, :test]},
      {:membrane_element_rawvideo_parser, "~> 0.4.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      },
      files: ["lib", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs", "c_src"],
      exclude_patterns: [~r"c_src/.*/_generated.*"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.FFmpeg.VideoFilter]
    ]
  end
end
