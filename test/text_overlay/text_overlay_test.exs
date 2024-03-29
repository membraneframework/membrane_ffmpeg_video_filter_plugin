defmodule TextOverlay.TextOverlayTest do
  use ExUnit.Case, async: true

  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions

  alias Membrane.FFmpeg.VideoFilter.TextOverlay
  alias Membrane.Testing.Pipeline
  alias VideoFilter.Helpers

  @tag :tmp_dir
  test "overlay given text with default settings", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("2s_8fps.h264", "ref-defaults.yuv", tmp_dir)

    pipeline =
      Pipeline.start_link_supervised!(
        spec:
          child(:src, %Membrane.File.Source{chunk_size: 40_960, location: in_path})
          |> child(:parser, %Membrane.H264.Parser{
            generate_best_effort_timestamps: %{framerate: {8, 1}}
          })
          |> child(:decoder, Membrane.H264.FFmpeg.Decoder)
          |> child(:text_filter, %TextOverlay{text: "Some very long text"})
          |> child(:sink, %Membrane.File.Sink{location: out_path})
      )

    assert_end_of_stream(pipeline, :sink, :input, 4000)

    Helpers.create_ffmpeg_reference(
      in_path,
      ref_path,
      "drawtext=text='Some very long text':x=w/100:y=(h-text_h)-w/100"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "overlay given text with centered text", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("2s_8fps.h264", "ref-centered.yuv", tmp_dir)

    pipeline =
      Pipeline.start_link_supervised!(
        spec: [
          child(:src, %Membrane.File.Source{chunk_size: 40_960, location: in_path})
          |> child(:parser, %Membrane.H264.Parser{
            generate_best_effort_timestamps: %{framerate: {8, 1}}
          })
          |> child(:decoder, Membrane.H264.FFmpeg.Decoder)
          |> child(:text_filter, %TextOverlay{
            text: "My text",
            horizontal_align: :center,
            vertical_align: :center
          })
          |> child(:sink, %Membrane.File.Sink{location: out_path})
        ]
      )

    assert_end_of_stream(pipeline, :sink, :input, 4000)

    Helpers.create_ffmpeg_reference(
      in_path,
      ref_path,
      "drawtext=text='My text':x=(w-text_w)/2:y=(h-text_h)/2"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "overlay given text with all settings applied", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} = Helpers.prepare_paths("2s_8fps.h264", "ref-all.yuv", tmp_dir)

    pipeline =
      Pipeline.start_link_supervised!(
        spec: [
          child(:src, %Membrane.File.Source{chunk_size: 40_960, location: in_path})
          |> child(:parser, %Membrane.H264.Parser{
            generate_best_effort_timestamps: %{framerate: {8, 1}}
          })
          |> child(:decoder, Membrane.H264.FFmpeg.Decoder)
          |> child(:text_filter, %TextOverlay{
            text: "My text",
            font_size: 35,
            font_color: "white",
            border_width: 1,
            border_color: "red",
            box?: true,
            box_color: "orange",
            horizontal_align: :center,
            vertical_align: :top
          })
          |> child(:sink, %Membrane.File.Sink{location: out_path})
        ]
      )

    assert_end_of_stream(pipeline, :sink, :input, 4000)

    Helpers.create_ffmpeg_reference(
      in_path,
      ref_path,
      "drawtext=text='My text':fontcolor=white:box=1:boxcolor=orange:borderw=1:bordercolor=red:fontsize=35:x=(w-text_w)/2:y=w/100"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  # due to different FFMPeg versions, the output may differ slightly on the CI server
  @tag :tmp_dir
  @tag :skip_ci
  test "apply text interval on the part of the video", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("4s_2fps.h264", "ref-intervals.yuv", tmp_dir)

    start_sec = 1.5
    end_sec = 2.0

    pipeline =
      Pipeline.start_link_supervised!(
        spec: [
          child(:src, %Membrane.File.Source{chunk_size: 40_960, location: in_path})
          |> child(:parser, %Membrane.H264.Parser{
            generate_best_effort_timestamps: %{framerate: {2, 1}}
          })
          |> child(:decoder, Membrane.H264.FFmpeg.Decoder)
          |> child(
            :text_filter,
            %TextOverlay{
              text_intervals: [
                {{Membrane.Time.milliseconds(trunc(start_sec * 1000)),
                  Membrane.Time.milliseconds(trunc(end_sec * 1000))}, "some text"}
              ],
              font_size: 35,
              font_color: "white",
              horizontal_align: :center,
              vertical_align: :top
            }
          )
          |> child(:sink, %Membrane.File.Sink{location: out_path})
        ]
      )

    assert_end_of_stream(pipeline, :sink, :input, 4000)

    Helpers.create_ffmpeg_reference(
      in_path,
      ref_path,
      "drawtext=text='some text':fontcolor=white:fontsize=35:x=(w-text_w)/2:y=w/100:enable='between(t,#{start_sec - 0.1},#{end_sec - 0.1})'"
    )

    Helpers.compare_contents(out_path, ref_path)
  end

  @tag :tmp_dir
  test "apply text interval on the part of the video with tricky fps", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} =
      Helpers.prepare_paths("3s_9fps.h264", "ref-odd-fps.yuv", tmp_dir)

    pipeline =
      Pipeline.start_link_supervised!(
        spec: [
          child(:src, %Membrane.File.Source{chunk_size: 40_960, location: in_path})
          |> child(:parser, %Membrane.H264.Parser{
            generate_best_effort_timestamps: %{framerate: {9, 1}}
          })
          |> child(:decoder, Membrane.H264.FFmpeg.Decoder)
          |> child(:text_filter, %TextOverlay{
            text_intervals: [
              {{Membrane.Time.milliseconds(1000), Membrane.Time.milliseconds(2000)}, "some text"}
            ],
            font_size: 35,
            font_color: "white",
            horizontal_align: :center,
            vertical_align: :top
          })
          |> child(:sink, %Membrane.File.Sink{location: out_path})
        ]
      )

    assert_end_of_stream(pipeline, :sink, :input, 4000)

    Helpers.create_ffmpeg_reference(
      in_path,
      ref_path,
      "drawtext=text='some text':fontcolor=white:fontsize=35:x=(w-text_w)/2:y=w/100:enable='between(t,0.9,1.9)'"
    )

    Helpers.compare_contents(out_path, ref_path)
  end
end
