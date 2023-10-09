# Membrane FFmpeg Video Filter Plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_ffmpeg_video_filter_plugin.svg)](https://hex.pm/packages/membrane_ffmpeg_video_filter_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_ffmpeg_video_filter_plugin)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_ffmpeg_video_filter_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_ffmpeg_video_filter_plugin)

This package contains elements providing video filters based on [ffmpeg video filter feature](https://ffmpeg.org/ffmpeg-filters.html#Video-Filters).

Currently only the TextOverlay element is implemented, based on [ffmpeg drawtext filter](https://ffmpeg.org/ffmpeg-filters.html#drawtext-1).
This element enables adding text on top of given raw video frames.

PRs with the implementation of other video filters are welcome!

## Installation

The package can be installed by adding `membrane_ffmpeg_video_filter_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
  	{:membrane_ffmpeg_video_filter_plugin, "~> 0.11.0"}
  ]
end
```

The precompiled builds of the [ffmpeg](https://www.ffmpeg.org) will be pulled and linked automatically. However, should there be any problems, consider installing it manually.

### Manual instalation of dependencies

#### macOS

```shell
brew install ffmpeg
```

#### Ubuntu

```shell
sudo apt-get install ffmpeg
```

#### Arch / Manjaro

```shell
pacman -S ffmpeg
```

## Usage

### TextOverlay

Below example pipeline adds "John Doe" text over h264 video in a specified style.

```elixir
defmodule VideoFilter.Pipeline do
  use Membrane.Pipeline

  alias Membrane.File.{Sink, Source}
  alias Membrane.H264.FFmpeg.{Parser, Decoder, Encoder}
  alias Membrane.FFmpeg.VideoFilter.TextOverlay

  @impl true
  def handle_init(_ctx, _opts) do
    structure =
      child(:file_src, %Source{location: "input.h264"})
      |> child(:parser, %Parser{framerate: {10, 1}})
      |> child(:decoder, Decoder)
      |> child(:text_filter, %TextOverlay{
          text: "John Doe",
          x: :center,
          fontsize: 25,
          fontcolor: "white",
          border?: true
        }
      )
      |> child(:encoder,  Encoder)
      |> child(:file_sink,  %Sink{location: "output.h264"})

    {[spec: structure], %{}}
  end
end
```

Frame from original video:

![input](readme/input.png)

Output frame with filter applied:

![output](readme/output.png)

## Copyright and License

Copyright 2021, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_ffmpeg_video_filter_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_ffmpeg_video_filter_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
