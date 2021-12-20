defmodule Membrane.FFmpeg.VideoFilter.TextOverlay.Native do
  @moduledoc false
  use Unifex.Loader

  @spec apply_filter!(Membrane.Buffer.t(), any) :: Membrane.Buffer.t()
  def apply_filter!(%{payload: payload} = buffer, native_state) do
    case apply_filter(payload, native_state) do
      {:ok, frame} ->
        %{buffer | payload: frame}

      {:error, reason} ->
        raise inspect(reason)
    end
  end
end
