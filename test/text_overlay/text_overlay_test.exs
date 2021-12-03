defmodule TextOverlay.TextOverlayTest do
  use ExUnit.Case, async: true

  import Membrane.Testing.Assertions

  alias Membrane.FFmpeg.VideoFilter.TextOverlay
  alias Membrane.Testing.Pipeline
  alias VideoFilter.Helpers

  @tag :tmp_dir
  test "overlay given text with default settings", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("640x360.h264", "ref-defaults.yuv", tmp_dir)

    assert {:ok, pid} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{chunk_size: 40_960, location: in_path},
                 parser: %Membrane.H264.FFmpeg.Parser{framerate: {8, 1}},
                 decoder: Membrane.H264.FFmpeg.Decoder,
                 text_filter: %TextOverlay{text: "Some very long text"},
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.create_ffmpeg_reference(
      "640x360.h264",
      ref_path,
      "drawtext=text='Some very long text':x=w/100:y=(h-text_h)-w/100"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "overlay given text with centered text", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("640x360.h264", "ref-centered.yuv", tmp_dir)

    assert {:ok, pid} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{chunk_size: 40_960, location: in_path},
                 parser: %Membrane.H264.FFmpeg.Parser{framerate: {8, 1}},
                 decoder: Membrane.H264.FFmpeg.Decoder,
                 text_filter: %TextOverlay{
                   text: "My text",
                   vertical_align: :center,
                   horizontal_align: :center
                 },
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.create_ffmpeg_reference(
      "640x360.h264",
      ref_path,
      "drawtext=text='My text':x=(w-text_w)/2:y=(h-text_h)/2"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "overlay given text with all settings applied", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} = Helpers.prepare_paths("640x360.h264", "ref-all.yuv", tmp_dir)

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
                   vertical_align: :center,
                   horizontal_align: :top
                 },
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.create_ffmpeg_reference(
      "640x360.h264",
      ref_path,
      "drawtext=text='My text':fontcolor=white:box=1:boxcolor=orange:borderw=1:bordercolor=DarkGray:fontsize=35:x=(w-text_w)/2:y=w/100"
    )

    Helpers.compare_contents(out_path, ref_path)
  end
end
