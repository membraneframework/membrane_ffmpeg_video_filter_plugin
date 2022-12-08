defmodule Membrane.FFmpeg.VideoFilter.TextOverlay do
  @moduledoc """
  Element adding text overlay to raw video frames - using 'drawtext' video filter from FFmpeg Library.
  (https://ffmpeg.org/ffmpeg-filters.html#drawtext-1).
  Element allows for specifying most commonly used 'drawtext' settings (such as fontsize, fontcolor) through element options.

  The element expects each frame to be received in a separate buffer.
  Additionally, the element has to receive proper stream format with picture format and dimensions.
  """
  use Membrane.Filter

  require Membrane.Logger

  alias __MODULE__.Native
  alias Membrane.{Buffer, RawVideo}

  def_options text: [
                type: :binary,
                description:
                  "Text to be displayed on video. Either text or text_intervals must be provided",
                default: nil
              ],
              text_intervals: [
                type: :list,
                spec: [{{Time.t(), Time.t() | :infinity}, String.t()}],
                description:
                  "List of time intervals when each given text should appear. Intervals should not overlap.
                Either text or text_intervals must be provided",
                default: []
              ],
              font_size: [
                type: :int,
                description: "Size of the displayed font",
                default: 12
              ],
              font_color: [
                type: :binary,
                description:
                  "Choose font color according to the ffmpeg color syntax (https://ffmpeg.org/ffmpeg-utils.html#color-syntax)",
                default: "black"
              ],
              font_file: [
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
              box_color: [
                type: :binary,
                description: "If the box? is set to true, display a box in the given color",
                default: "white"
              ],
              border_width: [
                type: :int,
                description: "Set the width of the border around the text",
                default: 0
              ],
              border_color: [
                type: :binary,
                description: "Set the color of the border, if exists",
                default: "black"
              ],
              horizontal_align: [
                type: :atom,
                spec: :left | :right | :center,
                description: "Horizontal position of the displayed text",
                default: :left
              ],
              vertical_align: [
                type: :atom,
                spec: :top | :bottom | :center,
                description: "Vertical position of the displayed text",
                default: :bottom
              ]

  def_input_pad :input,
    demand_mode: :auto,
    demand_unit: :buffers,
    accepted_format: %RawVideo{aligned: true}

  def_output_pad :output,
    demand_mode: :auto,
    accepted_format: %RawVideo{aligned: true}

  @impl true
  def handle_init(_ctx, options) do
    text_intervals = convert_to_text_intervals(options)

    state =
      options
      |> Map.from_struct()
      |> Map.delete(:text)
      |> Map.put(:text_intervals, text_intervals)
      |> Map.put(:native_state, nil)

    {[], state}
  end

  defp convert_to_text_intervals(%{text: nil, text_intervals: []}) do
    Membrane.Logger.warn("No text or text_intervals provided, no text will be added to video")
    []
  end

  defp convert_to_text_intervals(%{text: nil, text_intervals: text_intervals}) do
    text_intervals
  end

  defp convert_to_text_intervals(%{text: text, text_intervals: []}) do
    [{{0, :infinity}, text}]
  end

  defp convert_to_text_intervals(%{text: _text, text_intervals: _text_intervals}) do
    raise "Both 'text' and 'text_intervals' have been provided - choose one input method."
  end

  @impl true
  def handle_stream_format(:input, stream_format, _context, state) do
    state = init_new_filter_if_needed(stream_format, state)
    {[stream_format: {:output, stream_format}], state}
  end

  @impl true
  def handle_process(
        :input,
        %Buffer{pts: nil} = buffer,
        _ctx,
        %{text_intervals: intervals} = state
      ) do
    case intervals do
      [{{0, :infinity}, _text}] ->
        buffer = Native.apply_filter!(buffer, state.native_state)
        {[buffer: {:output, buffer}], state}

      _intervals ->
        raise "Received stream without pts - cannot apply filter according to provided `text_intervals`"
    end
  end

  def handle_process(:input, buffer, ctx, state) do
    {buffer, state} = apply_filter_if_needed(buffer, ctx, state)
    {[buffer: {:output, buffer}], state}
  end

  # no text left to render
  defp apply_filter_if_needed(buffer, _ctx, %{text_intervals: []} = state) do
    {buffer, state}
  end

  defp apply_filter_if_needed(
         buffer,
         ctx,
         %{native_state: native_state, text_intervals: [{interval, _text} | intervals]} = state
       ) do
    cond do
      frame_before_interval?(buffer, interval) ->
        {buffer, state}

      frame_after_interval?(buffer, interval) ->
        state = %{state | text_intervals: intervals}
        state = init_new_filter_if_needed(ctx.pads.input.stream_format, state)
        apply_filter_if_needed(buffer, ctx, state)

      frame_in_interval?(buffer, interval) ->
        buffer = Native.apply_filter!(buffer, native_state)
        {buffer, state}
    end
  end

  defp init_new_filter_if_needed(_stream_format, %{text_intervals: []} = state), do: state

  defp init_new_filter_if_needed(
         stream_format,
         %{text_intervals: [text_interval | _intervals]} = state
       ) do
    {_interval, text} = text_interval

    case Native.create(
           text,
           stream_format.width,
           stream_format.height,
           stream_format.pixel_format,
           state.font_size,
           state.font_color,
           font_file_to_native_format(state.font_file),
           state.box?,
           state.box_color,
           state.border_width,
           state.border_color,
           state.horizontal_align,
           state.vertical_align
         ) do
      {:ok, native_state} ->
        %{state | native_state: native_state}

      {:error, reason} ->
        raise inspect(reason)
    end
  end

  defp frame_before_interval?(%Buffer{pts: pts}, {from, _to}) do
    pts < from
  end

  defp frame_after_interval?(_buffer, {_from, :infinity}), do: false

  defp frame_after_interval?(%Buffer{pts: pts}, {_from, to}) do
    pts >= to
  end

  defp frame_in_interval?(%Buffer{pts: pts}, {from, :infinity}) do
    pts >= from
  end

  defp frame_in_interval?(%Buffer{pts: pts}, {from, to}) do
    pts < to and pts >= from
  end

  @impl true
  def handle_end_of_stream(:input, _context, state) do
    {[end_of_stream: :output], state}
  end

  defp font_file_to_native_format(nil), do: ""
  defp font_file_to_native_format(font_file), do: font_file
end
