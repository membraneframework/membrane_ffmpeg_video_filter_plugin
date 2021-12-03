#pragma once

#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>
#include <libavutil/imgutils.h>
#include <libavutil/opt.h>
#include <libavutil/parseutils.h>
#include <stdio.h>

typedef struct VfilterState {
  AVFilterContext *buffersink_ctx;
  AVFilterContext *buffersrc_ctx;
  AVFilterGraph *filter_graph;
  int width;
  int height;
  int pixel_format;
  char *text;
} State;

#include "_generated/text_overlay.h"
