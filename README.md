# Membrane FFmpeg Video Filter Plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_ffmpeg_video_filter_plugin.svg)](https://hex.pm/packages/membrane_ffmpeg_video_filter_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_ffmpeg_video_filter_plugin)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_ffmpeg_video_filter_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_ffmpeg_video_filter_plugin)

This package contains elements providing video filters based on [ffmpeg video filter feature](https://ffmpeg.org/ffmpeg-filters.html#Video-Filters).

Currently only the TextOverlay element is implemented, based on [ffmpeg drawtext filter](https://ffmpeg.org/ffmpeg-filters.html#drawtext-1).
This element enables adding text on top of given raw video frames.  

## Installation

The package can be installed by adding `membrane_ffmpeg_video_filter_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_ffmpeg_video_filter_plugin, "~> 0.1.0"}
  ]
end
```

## Usage

### TextOverlay

```elixir
defmodule VideoFilter.Pipeline do
  use Membrane.Pipeline

  alias Membrane.File.{Sink, Source}
  alias Membrane.H264.FFmpeg.{Parser, Decoder, Encoder}
  alias Membrane.FFmpeg.VideoFilter.TextOverlay

  @impl true
  def handle_init(_opts) do
    children = %{
      file_src: %Source{location: "input.h264"},
      parser: %Parser{framerate: {10, 1}},
      decoder: Decoder,
      text_filter: %TextOverlay{
        text: "My text",
        x: :center,
        fontsize: 30,
        fontcolor: "white",
        border?: true
      },
      encoder: Encoder,
      file_sink: %Sink{location: "output.h264"}
    }

    links = [
      link(:file_src)
      |> to(:parser)
      |> to(:decoder)
      |> to(:text_filter)
      |> to(:encoder)
      |> to(:file_sink)
    ]

    {{:ok, spec: %ParentSpec{children: children, links: links}}, %{}}
  end
end
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_ffmpeg_video_filter_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_ffmpeg_video_filter_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
