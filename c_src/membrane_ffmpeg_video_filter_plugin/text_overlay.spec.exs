module Membrane.FFmpeg.VideoFilter.TextOverlay.Native

state_type "State"

spec create(
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
       horizontal_align :: atom,
       vertical_align :: atom
     ) :: {:ok :: label, state} | {:error :: label, reason :: atom}

spec apply_filter(payload, state) :: {:ok :: label, payload} | {:error :: label, reason :: atom}

dirty :cpu, apply_filter: 2
