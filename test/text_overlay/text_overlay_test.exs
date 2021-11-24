defmodule TextOverlay.TextOverlayTest do
  use ExUnit.Case, async: true
  import Membrane.Testing.Assertions
  alias Membrane.FFmpeg.VideoFilter.TextOverlay
  alias Membrane.Testing.Pipeline

  defp prepare_paths(filename, testname) do
    in_path = "../fixtures/text_overlay/#{filename}" |> Path.expand(__DIR__)
    ref_path = "../fixtures/text_overlay/ref-#{testname}-#{filename}" |> Path.expand(__DIR__)
    out_path = "../fixtures/text_overlay/out-#{testname}-#{filename}" |> Path.expand(__DIR__)
    File.rm(out_path)
    on_exit(fn -> File.rm(out_path) end)
    {in_path, out_path, ref_path}
  end

  defp compare_contents(output_path, reference_path) do
    assert {:ok, reference_file} = File.read(reference_path)
    assert {:ok, output_file} = File.read(output_path)
    assert output_file == reference_file
  end

  test "overlay given text with default settings" do
    {in_path, out_path, ref_path} = prepare_paths("640x360.h264", "defaults")

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

    compare_contents(out_path, ref_path)
  end

  test "overlay given text with centered text" do
    {in_path, out_path, ref_path} = prepare_paths("640x360.h264", "centered")

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

    compare_contents(out_path, ref_path)
  end

  test "overlay given text with all settings applied" do
    {in_path, out_path, ref_path} = prepare_paths("640x360.h264", "all")

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

    compare_contents(out_path, ref_path)
  end
end
