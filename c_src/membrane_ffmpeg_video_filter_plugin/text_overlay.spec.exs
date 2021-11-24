module(Membrane.FFmpeg.VideoFilter.TextOverlay.Native)

state_type("State")

spec(
  create(
    text :: string,
    width :: int,
    height :: int,
    pixel_format_name :: atom,
    fontsize :: int,
    box :: int,
    boxcolor :: string,
    border :: int,
    fontcolor :: string,
    fontfile :: string,
    x :: atom,
    y :: atom
  ) :: {:ok :: label, state} | {:error :: label, reason :: atom}
)

spec(filter(payload, state) :: {:ok :: label, payload} | {:error :: label, reason :: atom})
