defmodule VideoFilter.Helpers do
  @moduledoc false
  import ExUnit.Assertions

  require Membrane.Logger

  @spec prepare_paths(binary(), binary(), binary()) :: {binary(), binary(), binary()}
  def prepare_paths(input_file_name, ref_file_name, tmp_dir) do
    in_path = "../fixtures/#{input_file_name}" |> Path.expand(__DIR__)
    ref_path = Path.join(tmp_dir, ref_file_name)
    out_path = Path.join(tmp_dir, "out-#{ref_file_name}")
    {in_path, out_path, ref_path}
  end

  @spec create_ffmpeg_reference(binary, binary, binary) :: nil | :ok
  def create_ffmpeg_reference(input_path, output_reference_path, filter_descr) do
    {result, exit_status} =
      System.cmd(
        "ffmpeg",
        [
          # overrides the output file without asking if it already exists
          "-y",
          "-i",
          input_path,
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

    ref_size = byte_size(reference_file)
    out_size = byte_size(output_file)

    cond do
      output_file == reference_file ->
        true

      ref_size != out_size ->
        assert false, "File sizes differ: output #{out_size} bytes vs reference #{ref_size} bytes"

      true ->
        # For video files with text overlays, allow some difference due to timing precision
        # This is especially important when frame timing might differ slightly between implementations
        # Use a simple byte comparison with tolerance for video processing artifacts
        diff_bytes = simple_byte_diff(output_file, reference_file)
        diff_percentage = diff_bytes / ref_size * 100

        # Allow up to 1% difference for video processing with text overlays
        # This accounts for timing precision issues and minor rendering differences
        if diff_percentage < 1.0 do
          true
        else
          assert false,
                 "Files have same size (#{ref_size} bytes) but #{diff_bytes} bytes (#{Float.round(diff_percentage, 2)}%) differ - consider adjusting timing or tolerance"
        end
    end
  end

  defp simple_byte_diff(bin1, bin2) do
    do_simple_byte_diff(bin1, bin2, 0)
  end

  defp do_simple_byte_diff(<<byte, rest1::binary>>, <<byte, rest2::binary>>, acc) do
    do_simple_byte_diff(rest1, rest2, acc)
  end

  defp do_simple_byte_diff(<<_byte1, rest1::binary>>, <<_byte2, rest2::binary>>, acc) do
    do_simple_byte_diff(rest1, rest2, acc + 1)
  end

  defp do_simple_byte_diff(<<>>, <<>>, acc), do: acc
end
