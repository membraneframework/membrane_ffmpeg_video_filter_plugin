defmodule VideoFilter.Helpers do
  @moduledoc false
  import ExUnit.Assertions

  require Membrane.Logger

  @spec prepare_paths(binary(), binary(), binary()) :: {binary(), binary(), binary()}
  def prepare_paths(input_file, ref_file, tmp_dir) do
    in_path = "../fixtures/#{input_file}" |> Path.expand(__DIR__)
    ref_path = "../fixtures/#{ref_file}" |> Path.expand(__DIR__)
    out_path = Path.join(tmp_dir, ref_file)
    {in_path, out_path, ref_path}
  end

  @spec create_ffmpeg_reference(binary, binary, binary) :: nil | :ok
  def create_ffmpeg_reference(input_file, output_reference_path, filter_descr) do
    full_input_path = "../fixtures/#{input_file}" |> Path.expand(__DIR__)

    {result, exit_status} =
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

    if exit_status != 0 do
      raise inspect(result)
    end
  end

  @spec compare_contents(binary(), binary()) :: true
  def compare_contents(output_path, reference_path) do
    {:ok, reference_file} = File.read(reference_path)
    {:ok, output_file} = File.read(output_path)
    assert output_file == reference_file
  end
end
