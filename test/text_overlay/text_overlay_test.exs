defmodule TextOverlay.TextOverlayTest do
  use ExUnit.Case, async: true
  import Membrane.Testing.Assertions
  alias TextOverlay.Helpers
  alias Membrane.FFmpeg.VideoFilter.TextOverlay
  alias Membrane.Testing.Pipeline

  test "overlay given text with default settings" do
    {in_path, out_path, ref_path} = Helpers.prepare_paths("640x360.h264", "defaults")

    assert {:ok, pid} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{chunk_size: 40_960, location: in_path},
                 parser: %Membrane.H264.FFmpeg.Parser{framerate: {8, 1}},
                 decoder: Membrane.H264.FFmpeg.Decoder,
                 text_filter: %TextOverlay{text: "Some very long text"},
                 encoder: Membrane.H264.FFmpeg.Encoder,
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.compare_contents(out_path, ref_path)
  end

  test "overlay given text with centered text" do
    {in_path, out_path, ref_path} = Helpers.prepare_paths("640x360.h264", "centered")

    assert {:ok, pid} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{chunk_size: 40_960, location: in_path},
                 parser: %Membrane.H264.FFmpeg.Parser{framerate: {8, 1}},
                 decoder: Membrane.H264.FFmpeg.Decoder,
                 text_filter: %TextOverlay{
                   text: "My text",
                   x: :center,
                   y: :center
                 },
                 encoder: Membrane.H264.FFmpeg.Encoder,
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.compare_contents(out_path, ref_path)
  end

  test "overlay given text with all settings applied" do
    {in_path, out_path, ref_path} = Helpers.prepare_paths("640x360.h264", "all")

    assert {:ok, pid} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{chunk_size: 40_960, location: in_path},
                 parser: %Membrane.H264.FFmpeg.Parser{framerate: {8, 1}},
                 decoder: Membrane.H264.FFmpeg.Decoder,
                 text_filter: %TextOverlay{
                   text: "My text",
                   fontsize: 35,
                   fontcolor: "white",
                   border?: true,
                   box?: true,
                   boxcolor: "orange",
                   x: :center,
                   y: :top
                 },
                 encoder: Membrane.H264.FFmpeg.Encoder,
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.compare_contents(out_path, ref_path)
  end
end
