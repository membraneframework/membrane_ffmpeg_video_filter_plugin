defmodule TextOverlay.NativeTest do
  use ExUnit.Case, async: true

  alias Membrane.FFmpeg.VideoFilter.TextOverlay.Native
  alias VideoFilter.Helpers

  @tag :tmp_dir
  test "overlay text over raw video frame", %{tmp_dir: tmp_dir} do
    {in_path, out_path, ref_path} = Helpers.prepare_paths("1frame.yuv", "ref-native.yuv", tmp_dir)
    assert {:ok, frame} = File.read(in_path)

    assert {:ok, ref} =
             Native.create(
               "mtext",
               640,
               360,
               :I420,
               12,
               "white",
               "",
               false,
               "",
               0,
               "",
               :center,
               :top
             )

    assert {:ok, out_frame} = Native.apply_filter(frame, ref)
    assert {:ok, file} = File.open(out_path, [:write])
    on_exit(fn -> File.close(file) end)

    IO.binwrite(file, out_frame)
    reference_input_path = "../fixtures/1frame.h264" |> Path.expand(__DIR__)

    Helpers.create_ffmpeg_reference(
      reference_input_path,
      ref_path,
      "drawtext=text=mtext:fontcolor=white:y=w/100:x=(w-text_w)/2"
    )

    Helpers.compare_contents(out_path, ref_path)
  end
end
