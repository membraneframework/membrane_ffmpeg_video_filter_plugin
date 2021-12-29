#include "text_overlay.h"

int get_pixel_format(char *fmt_name);
static int init_filters(const char *filters_descr, State *state);
void create_filter_description(char *filter_descr, int len, char *text,
                               int fontsize, int box, char *boxcolor,
                               int borderw, char *bordercolor, char *fontcolor,
                               char *fontfile, char *horizontal_align,
                               char *vertical_align);

UNIFEX_TERM create(UnifexEnv *env, char *text, int width, int height,
                   char *pixel_format_name, int fontsize, int box,
                   char *boxcolor, int borderw, char *bordercolor,
                   char *fontcolor, char *fontfile, char *horizontal_align,
                   char *vertical_align) {

  UNIFEX_TERM result;
  State *state = unifex_alloc_state(env);
  state->width = width;
  state->height = height;

  int pix_fmt = get_pixel_format(pixel_format_name);
  if (pix_fmt < 0) {
    result = create_result_error(env, "unsupported_pixel_format");
    goto exit_create;
  }
  state->pixel_format = pix_fmt;

  char filter_descr[512];
  create_filter_description(filter_descr, 512, text, fontsize, box, boxcolor,
                            borderw, bordercolor, fontcolor, fontfile,
                            horizontal_align, vertical_align);
  if (init_filters(filter_descr, state) < 0) {
    result = create_result_error(env, "error_creating_filters");
    goto exit_create;
  }
  result = create_result_ok(env, state);

exit_create:
  unifex_release_state(env, state);
  return result;
}

UNIFEX_TERM apply_filter(UnifexEnv *env, UnifexPayload *payload, State *state) {

  UNIFEX_TERM res;
  int ret = 0;
  AVFrame *frame = av_frame_alloc();
  AVFrame *filtered_frame = av_frame_alloc();

  if (!frame || !filtered_frame) {
    res = apply_filter_result_error(env, "error_allocating_frame");
    goto exit_filter;
  }

  frame->format = state->pixel_format;
  frame->width = state->width;
  frame->height = state->height;
  av_image_fill_arrays(frame->data, frame->linesize, payload->data,
                       frame->format, frame->width, frame->height, 1);

  /* feed the filtergraph */
  if (av_buffersrc_add_frame_flags(state->buffersrc_ctx, frame,
                                   AV_BUFFERSRC_FLAG_KEEP_REF) < 0) {
    res = apply_filter_result_error(env, "error_feeding_filtergraph");
    goto exit_filter;
  }

  /* pull filtered frame from the filtergraph - in drawtext filter there should
   * always be 1 frame on output for each frame on input*/
  ret = av_buffersink_get_frame(state->buffersink_ctx, filtered_frame);
  if (ret < 0) {
    res = apply_filter_result_error(env, "error_pulling_from_filtergraph");
    goto exit_filter;
  }

  UnifexPayload payload_frame;
  size_t payload_size = av_image_get_buffer_size(
      filtered_frame->format, filtered_frame->width, filtered_frame->height, 1);
  unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, payload_size,
                       &payload_frame);

  if (av_image_copy_to_buffer(payload_frame.data, payload_size,
                              (const uint8_t *const *)filtered_frame->data,
                              filtered_frame->linesize, filtered_frame->format,
                              filtered_frame->width, filtered_frame->height,
                              1) < 0) {
    res = apply_filter_result_error(env, "copy_to_payload");
    goto exit_filter;
  }
  res = apply_filter_result_ok(env, &payload_frame);
exit_filter:
  if (frame != NULL)
    av_frame_free(&frame);
  if (filtered_frame != NULL)
    av_frame_free(&filtered_frame);
  return res;
}

int get_pixel_format(char *fmt_name) {
  int pix_fmt = -1;
  if (strcmp(fmt_name, "I420") == 0) {
    pix_fmt = AV_PIX_FMT_YUV420P;
  } else if (strcmp(fmt_name, "I422") == 0) {
    pix_fmt = AV_PIX_FMT_YUV422P;
  } else if (strcmp(fmt_name, "I444") == 0) {
    pix_fmt = AV_PIX_FMT_YUV444P;
  }
  return pix_fmt;
}

void create_filter_description(char *filter_descr, int len, char *text,
                               int fontsize, int box, char *boxcolor,
                               int borderw, char *bordercolor, char *fontcolor,
                               char *fontfile, char *horizontal_align,
                               char *vertical_align) {
  filter_descr += snprintf(filter_descr, len, "drawtext=text=%s", text);
  if (fontsize != -1) {
    filter_descr += snprintf(filter_descr, len, ":fontsize=%d", fontsize);
  }
  if (box != -1) {
    filter_descr += snprintf(filter_descr, len, ":box=%d", box);
  }
  if (strcmp(boxcolor, "") != 0) {
    filter_descr += snprintf(filter_descr, len, ":boxcolor=%s", boxcolor);
  }
  if (strcmp(fontcolor, "") != 0) {
    filter_descr += snprintf(filter_descr, len, ":fontcolor=%s", fontcolor);
  }
  if (strcmp(fontfile, "") != 0) {
    filter_descr += snprintf(filter_descr, len, ":fontfile=%s", fontfile);
  }
  if (borderw > 0) {
    filter_descr += snprintf(filter_descr, len, ":bordercolor=%s:borderw=%d",
                             bordercolor, borderw);
  }
  if (strcmp(horizontal_align, "center") == 0) {
    filter_descr += snprintf(filter_descr, len, ":x=(w-text_w)/2");
  } else if (strcmp(horizontal_align, "right") == 0) {
    // leave 1% margin to the border
    filter_descr += snprintf(filter_descr, len, ":x=(w-text_w)-w/100");
  } else if (strcmp(horizontal_align, "left") == 0) {
    // leave 1% margin to the border
    filter_descr += snprintf(filter_descr, len, ":x=w/100");
  } else { // literal
    filter_descr += snprintf(filter_descr, len, ":x=%s", horizontal_align);
  }
  if (strcmp(vertical_align, "center") == 0) {
    filter_descr += snprintf(filter_descr, len, ":y=(h-text_h)/2");
  } else if (strcmp(vertical_align, "top") == 0) {
    // set the same margin for width and height
    filter_descr += snprintf(filter_descr, len, ":y=w/100");
  } else if (strcmp(vertical_align, "bottom") == 0) {
    filter_descr += snprintf(filter_descr, len, ":y=(h-text_h)-w/100");
  } else { // literal
    filter_descr += snprintf(filter_descr, len, ":y=%s", vertical_align);
  }
}

static int init_filters(const char *filters_descr, State *state) {
  char args[512];
  int ret = 0;
  const AVFilter *buffersrc = avfilter_get_by_name("buffer");
  const AVFilter *buffersink = avfilter_get_by_name("buffersink");
  AVFilterInOut *outputs = avfilter_inout_alloc();
  AVFilterInOut *inputs = avfilter_inout_alloc();
  enum AVPixelFormat pix_fmts[] = {state->pixel_format, AV_PIX_FMT_NONE};
  state->filter_graph = avfilter_graph_alloc();

  if (!buffersrc || !buffersink || !outputs || !inputs ||
      !state->filter_graph) {
    ret = AVERROR(ENOMEM);
    goto exit_init_filter;
  }
  snprintf(args, sizeof(args), "video_size=%dx%d:pix_fmt=%d:time_base=1/1",
           state->width, state->height, state->pixel_format);

  ret = avfilter_graph_create_filter(&state->buffersrc_ctx, buffersrc, "in",
                                     args, NULL, state->filter_graph);
  if (ret < 0) {
    av_log(NULL, AV_LOG_ERROR, "Cannot create buffer source\n");
    goto exit_init_filter;
  }

  ret = avfilter_graph_create_filter(&state->buffersink_ctx, buffersink, "out",
                                     NULL, NULL, state->filter_graph);
  if (ret < 0) {
    av_log(NULL, AV_LOG_ERROR, "Cannot create buffer sink\n");
    goto exit_init_filter;
  }

  ret = av_opt_set_int_list(state->buffersink_ctx, "pix_fmts", pix_fmts,
                            AV_PIX_FMT_NONE, AV_OPT_SEARCH_CHILDREN);
  if (ret < 0) {
    av_log(NULL, AV_LOG_ERROR, "Cannot set output pixel format\n");
    goto exit_init_filter;
  }

  outputs->name = av_strdup("in");
  outputs->filter_ctx = state->buffersrc_ctx;
  outputs->pad_idx = 0;
  outputs->next = NULL;

  inputs->name = av_strdup("out");
  inputs->filter_ctx = state->buffersink_ctx;
  inputs->pad_idx = 0;
  inputs->next = NULL;

  if ((ret = avfilter_graph_parse_ptr(state->filter_graph, filters_descr,
                                      &inputs, &outputs, NULL)) < 0) {
    av_log(NULL, AV_LOG_ERROR, "graph creating error\n");
    goto exit_init_filter;
  }
  if ((ret = avfilter_graph_config(state->filter_graph, NULL)) < 0)
    goto exit_init_filter;

exit_init_filter:
  avfilter_inout_free(&inputs);
  avfilter_inout_free(&outputs);

  return ret;
}

void handle_destroy_state(UnifexEnv *env, State *state) {
  UNIFEX_UNUSED(env);
  if (state->filter_graph != NULL) {
    avfilter_graph_free(&state->filter_graph);
  }
  state->buffersink_ctx = NULL;
  state->buffersrc_ctx = NULL;
}
