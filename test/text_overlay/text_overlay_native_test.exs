defmodule TextOverlay.NativeTest do
  use ExUnit.Case, async: true
  alias Membrane.FFmpeg.VideoFilter.TextOverlay.Native
  alias TextOverlay.Helpers

  test "overlay text over raw video frame" do
    {in_path, out_path, ref_path} = Helpers.prepare_paths("1frame.yuv", "native", ".yuv")
    assert {:ok, frame} = File.read(in_path)

    assert {:ok, ref} =
             Native.create("mtext", 640, 360, :I420, -1, -1, "", 0, "white", "", :center, :top)

    assert {:ok, out_frame} = Native.filter(frame, ref)
    assert {:ok, file} = File.open(out_path, [:write])

    IO.binwrite(file, out_frame)
    File.close(file)

    Helpers.create_ffmpeg_reference(
      "1frame.h264",
      ref_path,
      "drawtext=text=mtext:fontcolor=white:y=w/100:x=(w-text_w)/2"
    )

    Helpers.compare_contents(out_path, ref_path)
  end
end
