// thumbnail.cpp
#include "thumbnail.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

#include <vector>
#include <cstring>

uint8_t* extract_thumbnail(const char* video_path, int* out_size) {
    AVFormatContext* format_ctx = nullptr;

    if (avformat_open_input(&format_ctx, video_path, nullptr, nullptr) != 0)
        return nullptr;

    if (avformat_find_stream_info(format_ctx, nullptr) < 0)
        return nullptr;

    int video_stream_index = -1;
    for (unsigned int i = 0; i < format_ctx->nb_streams; i++) {
        if (format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
            break;
        }
    }

    if (video_stream_index == -1)
        return nullptr;

    AVCodecParameters* codec_par = format_ctx->streams[video_stream_index]->codecpar;
    const AVCodec* codec = avcodec_find_decoder(codec_par->codec_id);
    if (!codec) return nullptr;

    AVCodecContext* codec_ctx = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(codec_ctx, codec_par);

    if (avcodec_open2(codec_ctx, codec, nullptr) < 0)
        return nullptr;

    AVPacket* packet = av_packet_alloc();
    AVFrame* frame = av_frame_alloc();

    bool frame_found = false;

    while (av_read_frame(format_ctx, packet) >= 0) {
        if (packet->stream_index == video_stream_index) {
            avcodec_send_packet(codec_ctx, packet);
            if (avcodec_receive_frame(codec_ctx, frame) == 0) {
                frame_found = true;
                break;
            }
        }
        av_packet_unref(packet);
    }

    if (!frame_found) return nullptr;

    // Convert to RGB
    SwsContext* sws_ctx = sws_getContext(
            codec_ctx->width, codec_ctx->height, codec_ctx->pix_fmt,
            codec_ctx->width, codec_ctx->height, AV_PIX_FMT_RGB24,
            SWS_BILINEAR, nullptr, nullptr, nullptr
    );

    AVFrame* rgb_frame = av_frame_alloc();
    int num_bytes = av_image_get_buffer_size(
            AV_PIX_FMT_RGB24,
            codec_ctx->width,
            codec_ctx->height,
            1
    );

    uint8_t* buffer = (uint8_t*)av_malloc(num_bytes);
    av_image_fill_arrays(
            rgb_frame->data,
            rgb_frame->linesize,
            buffer,
            AV_PIX_FMT_RGB24,
            codec_ctx->width,
            codec_ctx->height,
            1
    );

    sws_scale(
            sws_ctx,
            frame->data,
            frame->linesize,
            0,
            codec_ctx->height,
            rgb_frame->data,
            rgb_frame->linesize
    );

    // Encode to JPEG
    const AVCodec* jpeg_codec = avcodec_find_encoder(AV_CODEC_ID_MJPEG);
    AVCodecContext* jpeg_ctx = avcodec_alloc_context3(jpeg_codec);

    jpeg_ctx->pix_fmt = AV_PIX_FMT_YUVJ420P;
    jpeg_ctx->height = codec_ctx->height;
    jpeg_ctx->width = codec_ctx->width;
    jpeg_ctx->time_base = {1, 25};

    avcodec_open2(jpeg_ctx, jpeg_codec, nullptr);

    AVFrame* yuv_frame = av_frame_alloc();
    yuv_frame->format = jpeg_ctx->pix_fmt;
    yuv_frame->width = jpeg_ctx->width;
    yuv_frame->height = jpeg_ctx->height;

    av_frame_get_buffer(yuv_frame, 0);

    SwsContext* sws_ctx2 = sws_getContext(
            codec_ctx->width, codec_ctx->height, AV_PIX_FMT_RGB24,
            jpeg_ctx->width, jpeg_ctx->height, AV_PIX_FMT_YUVJ420P,
            SWS_BILINEAR, nullptr, nullptr, nullptr
    );

    sws_scale(
            sws_ctx2,
            rgb_frame->data,
            rgb_frame->linesize,
            0,
            codec_ctx->height,
            yuv_frame->data,
            yuv_frame->linesize
    );

    AVPacket* jpeg_pkt = av_packet_alloc();

    avcodec_send_frame(jpeg_ctx, yuv_frame);
    if (avcodec_receive_packet(jpeg_ctx, jpeg_pkt) != 0)
        return nullptr;

    uint8_t* result = (uint8_t*)malloc(jpeg_pkt->size);
    memcpy(result, jpeg_pkt->data, jpeg_pkt->size);

    *out_size = jpeg_pkt->size;

    // Cleanup (important)
    av_packet_free(&jpeg_pkt);
    av_frame_free(&yuv_frame);
    sws_freeContext(sws_ctx2);

    av_free(buffer);
    av_frame_free(&rgb_frame);
    sws_freeContext(sws_ctx);

    av_frame_free(&frame);
    av_packet_free(&packet);
    avcodec_free_context(&codec_ctx);
    avcodec_free_context(&jpeg_ctx);
    avformat_close_input(&format_ctx);

    return result;
}

void free_buffer(uint8_t* buffer) {
    free(buffer);
}