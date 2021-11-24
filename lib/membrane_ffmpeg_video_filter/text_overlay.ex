defmodule Membrane.FFmpeg.VideoFilter.TextOverlay do
  @moduledoc """
  Element adding text overlay to raw video frames - using 'drawtext' video filter from FFmpeg Library.
  (https://ffmpeg.org/ffmpeg-filters.html#drawtext-1).
  Element allows for specifying most commonly used 'drawtext' settings (such as fontsize, fontcolor) through element options.

  The element expects each frame to be received in a separate buffer.
  Additionally, the element has to receive proper caps with picture format and dimensions.
  """
  use Membrane.Filter
  alias __MODULE__.Native
  alias Membrane.Buffer
  alias Membrane.Caps.Video.Raw

  def_options text: [
                type: :binary,
                description: "Text to be displayed on video"
              ],
              fontsize: [
                type: :int,
                description:
                  "Size of the displayed font. If not set, ffmpeg's default value (16) is applied",
                default: nil
              ],
              fontcolor: [
                type: :binary,
                description:
                  "Choose font color according to the ffmpeg color syntax (https://ffmpeg.org/ffmpeg-utils.html#color-syntax).
                  If not set, ffmpeg's default value (black) is applied",
                default: nil
              ],
              fontfile: [
                type: :binary,
                description:
                  "Path to the file with the desired font. If not set, default font fallback from fontconfig is used",
                default: nil
              ],
              box?: [
                type: :boolean,
                description: "Set to true if a box is to be displayed behind the text",
                default: false
              ],
              boxcolor: [
                type: :binary,
                description: "If the box? is set to true, display a box in the given color",
                default: nil
              ],
              border?: [
                type: :boolean,
                description: "Set to true to display a gray border around letters",
                default: false
              ],
              x: [
                type: :atom,
                spec: :left | :right | :center,
                description: "Horizontal position of the displayed text",
                default: :left
              ],
              y: [
                type: :atom,
                spec: :top | :bottom | :center,
                description: "Vertical position of the displayed text",
                default: :bottom
              ]

  def_input_pad :input,
    demand_unit: :buffers,
    caps: {Raw, aligned: true}

  def_output_pad :output,
    caps: {Raw, aligned: true}

  @impl true
  def handle_init(options) do
    state =
      options
      |> Map.from_struct()
      |> Map.put(:native_state, nil)

    {:ok, state}
  end

  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, %{native_state: nil} = state) do
    # Wait until we have native state (after receiving caps)
    {:ok, state}
  end

  @impl true
  def handle_demand(:output, size, :buffers, _ctx, state) do
    {{:ok, demand: {:input, size}}, state}
  end

  @impl true
  def handle_process(
        :input,
        %Buffer{payload: payload} = buffer,
        _ctx,
        %{native_state: native_state} = state
      ) do
    case Native.filter(payload, native_state) do
      {:ok, frame} ->
        buffer = [buffer: {:output, %{buffer | payload: frame}}]
        {{:ok, buffer}, state}

      {:error, reason} ->
        {{:error, reason}, state}
    end
  end

  @impl true
  def handle_caps(
        :input,
        %Raw{format: format, width: width, height: height} = caps,
        _context,
        state
      ) do
    case Native.create(
           state.text,
           width,
           height,
           format,
           int_to_native_format(state.fontsize),
           boolean_to_native_format(state.box?),
           binary_to_native_format(state.boxcolor),
           boolean_to_native_format(state.border?),
           binary_to_native_format(state.fontcolor),
           binary_to_native_format(state.fontfile),
           state.x,
           state.y
         ) do
      {:ok, native_state} ->
        state = %{state | native_state: native_state}
        {{:ok, caps: {:output, caps}, redemand: :output}, state}

      {:error, reason} ->
        {{:error, reason}, state}
    end
  end

  @impl true
  def handle_end_of_stream(:input, _context, state) do
    {{:ok, end_of_stream: :output, notify: {:end_of_stream, :input}}, state}
  end

  @impl true
  def handle_prepared_to_stopped(_context, state) do
    {:ok, %{state | native_state: nil}}
  end

  defp int_to_native_format(nil), do: -1
  defp int_to_native_format(fontsize), do: fontsize
  defp binary_to_native_format(nil), do: ""
  defp binary_to_native_format(binary), do: binary
  defp boolean_to_native_format(false), do: 0
  defp boolean_to_native_format(true), do: 1
end
