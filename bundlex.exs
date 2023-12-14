defmodule Membrane.FFmpeg.VideoFilter.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives()
    ]
  end

  defp natives() do
    [
      text_overlay: [
        interface: :nif,
        sources: ["text_overlay.c"],
        os_deps: [
          ffmpeg: [
            {:precompiled, Membrane.PrecompiledDependencyProvider.get_dependency_url(:ffmpeg),
             ["libavutil", "libavfilter"]},
            {:pkg_config, ["libavutil", "libavfilter"]}
          ]
        ],
        preprocessor: Unifex
      ]
    ]
  end
end
