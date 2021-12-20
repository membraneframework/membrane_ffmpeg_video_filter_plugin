defmodule TextOverlay.TextOverlayTest do
  use ExUnit.Case, async: true

  import Membrane.Testing.Assertions

  alias Membrane.FFmpeg.VideoFilter.TextOverlay
  alias Membrane.Testing.Pipeline
  alias VideoFilter.Helpers

  @tag :tmp_dir
  test "overlay given text with default settings", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("2s_8fps.h264", "ref-defaults.yuv", tmp_dir)

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
      "2s_8fps.h264",
      ref_path,
      "drawtext=text='Some very long text':x=w/100:y=(h-text_h)-w/100"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "overlay given text with centered text", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("2s_8fps.h264", "ref-centered.yuv", tmp_dir)

    assert {:ok, pid} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{chunk_size: 40_960, location: in_path},
                 parser: %Membrane.H264.FFmpeg.Parser{framerate: {8, 1}},
                 decoder: Membrane.H264.FFmpeg.Decoder,
                 text_filter: %TextOverlay{
                   text: "My text",
                   horizontal_align: :center,
                   vertical_align: :center
                 },
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.create_ffmpeg_reference(
      "2s_8fps.h264",
      ref_path,
      "drawtext=text='My text':x=(w-text_w)/2:y=(h-text_h)/2"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "overlay given text with all settings applied", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} = Helpers.prepare_paths("2s_8fps.h264", "ref-all.yuv", tmp_dir)

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
                   horizontal_align: :center,
                   vertical_align: :top
                 },
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.create_ffmpeg_reference(
      "2s_8fps.h264",
      ref_path,
      "drawtext=text='My text':fontcolor=white:box=1:boxcolor=orange:borderw=1:bordercolor=DarkGray:fontsize=35:x=(w-text_w)/2:y=w/100"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "apply text interval on the part of the video", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("4s_2fps.h264", "ref-intervals.yuv", tmp_dir)

    assert {:ok, pid} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{chunk_size: 40_960, location: in_path},
                 parser: %Membrane.H264.FFmpeg.Parser{framerate: {2, 1}},
                 decoder: Membrane.H264.FFmpeg.Decoder,
                 text_filter: %TextOverlay{
                   text_intervals: [
                     {{Membrane.Time.milliseconds(1500), Membrane.Time.milliseconds(2000)},
                      "some text"}
                   ],
                   fontsize: 35,
                   fontcolor: "white",
                   horizontal_align: :center,
                   vertical_align: :top
                 },
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.create_ffmpeg_reference(
      "4s_2fps.h264",
      ref_path,
      "drawtext=text='some text':fontcolor=white:fontsize=35:x=(w-text_w)/2:y=w/100:enable='between(t,1,1.5)'"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "apply text interval on the part of the video with tricky fps", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("3s_9fps.h264", "ref-odd-fps.yuv", tmp_dir)

    assert {:ok, pid} =
             Pipeline.start_link(%Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{chunk_size: 40_960, location: in_path},
                 parser: %Membrane.H264.FFmpeg.Parser{framerate: {9, 1}},
                 decoder: Membrane.H264.FFmpeg.Decoder,
                 text_filter: %TextOverlay{
                   text_intervals: [
                     {{Membrane.Time.milliseconds(1000), Membrane.Time.milliseconds(2000)},
                      "some text"}
                   ],
                   fontsize: 35,
                   fontcolor: "white",
                   horizontal_align: :center,
                   vertical_align: :top
                 },
                 sink: %Membrane.File.Sink{location: out_path}
               ]
             })

    assert Pipeline.play(pid) == :ok
    assert_end_of_stream(pid, :sink, :input, 4000)
    Pipeline.stop_and_terminate(pid, blocking?: true)

    Helpers.create_ffmpeg_reference(
      "3s_9fps.h264",
      ref_path,
      "drawtext=text='some text':fontcolor=white:fontsize=35:x=(w-text_w)/2:y=w/100:enable='between(t,0.9,1.9)'"
    )

    Helpers.compare_contents(out_path, ref_path)
  end
end
