defmodule TextOverlay.Helpers do
  @moduledoc false
  import ExUnit.Assertions
  import ExUnit.Callbacks

  @spec prepare_paths(binary(), binary()) :: {binary(), binary(), binary()}
  def prepare_paths(filename, testname, out_extension \\ ".h264") do
    in_path = "../fixtures/text_overlay/#{filename}" |> Path.expand(__DIR__)
    ref_path = "../fixtures/text_overlay/ref-#{testname}#{out_extension}" |> Path.expand(__DIR__)
    out_path = "../fixtures/text_overlay/out-#{testname}#{out_extension}" |> Path.expand(__DIR__)
    File.rm(out_path)
    # on_exit(fn -> File.rm(out_path) end)
    {in_path, out_path, ref_path}
  end

  @spec create_ffmpeg_reference(binary, binary, binary) :: {any, non_neg_integer}
  def create_ffmpeg_reference(input_file, output_reference_path, filter_descr) do
    full_input_path = "../fixtures/text_overlay/#{input_file}" |> Path.expand(__DIR__)

    System.cmd(
      "ffmpeg",
      [
        # overrides the output file without asking if it already exists
        "-y",
        "-i",
        full_input_path,
        "-vf",
        filter_descr,
        output_reference_path
      ],
      stderr_to_stdout: true
    )
  end

  # ffmpeg -f rawvideo -pix_fmt yuv420p -s:v 640x360 -r 1 -i 1frame.yuv -c:v libx264 out.h264

  @spec compare_contents(binary(), binary()) :: true
  def compare_contents(output_path, reference_path) do
    {:ok, reference_file} = File.read(reference_path)
    {:ok, output_file} = File.read(output_path)
    assert output_file == reference_file
  end
end
