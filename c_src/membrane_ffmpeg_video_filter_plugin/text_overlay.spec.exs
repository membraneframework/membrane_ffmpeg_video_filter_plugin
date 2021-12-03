module Membrane.FFmpeg.VideoFilter.TextOverlay.Native

state_type "State"

spec(
  create(
    text :: string,
    width :: int,
    height :: int,
    pixel_format_name :: atom,
    fontsize :: int,
    box :: bool,
    boxcolor :: string,
    border :: bool,
    fontcolor :: string,
    fontfile :: string,
    vertical_align :: atom,
    horizontal_align :: atom
  ) :: {:ok :: label, state} | {:error :: label, reason :: atom}
)

spec(apply_filter(payload, state) :: {:ok :: label, payload} | {:error :: label, reason :: atom})
