defmodule TextOverlay.Helpers do
  @moduledoc false
  import ExUnit.Assertions
  import ExUnit.Callbacks

  @spec prepare_paths(binary(), binary()) :: {binary(), binary(), binary()}
  def prepare_paths(filename, testname) do
    in_path = "../fixtures/text_overlay/#{filename}" |> Path.expand(__DIR__)
    ref_path = "../fixtures/text_overlay/ref-#{testname}-#{filename}" |> Path.expand(__DIR__)
    out_path = "../fixtures/text_overlay/out-#{testname}-#{filename}" |> Path.expand(__DIR__)
    File.rm(out_path)
    on_exit(fn -> File.rm(out_path) end)
    {in_path, out_path, ref_path}
  end

  @spec compare_contents(binary(), binary()) :: true
  def compare_contents(output_path, reference_path) do
    {:ok, reference_file} = File.read(reference_path)
    {:ok, output_file} = File.read(output_path)
    assert output_file == reference_file
  end
end
