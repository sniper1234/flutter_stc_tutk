//#include "com_tutk_client_FFMPEG_Decoder.h"
//#include <stdlib.h>
//#include <string.h>
//#include <assert.h>
//#include <android/native_window.h>
//#include <android/native_window_jni.h>
//#include <android/log.h>
//#include <jni.h>
//#include <android/bitmap.h>
//#include <cstdio>
//
//#include "android/log.h"
//
//static const char *TAG = "ffmpeg";
//#define LOGI(fmt, args...) __android_log_print(ANDROID_LOG_INFO,  TAG, fmt, ##args)
//#define LOGD(fmt, args...) __android_log_print(ANDROID_LOG_DEBUG, TAG, fmt, ##args)
//#define LOGE(fmt, args...) __android_log_print(ANDROID_LOG_ERROR, TAG, fmt, ##args)
//
//extern "C" {
//#include "libavcodec/avcodec.h"
//#include "libavformat/avformat.h"
//#include "libavutil/rational.h"
//#include "libavutil/avutil.h"
//#include "libavutil/imgutils.h"
//#include "libavutil/frame.h"
//#include "libswscale/swscale.h"
//}
//
//#include "utils.h"
//
//#ifdef __cplusplus
//extern "C" {
//#endif
//
///*
// * Class:     com_tutk_client_FFMPEG_Decoder
// * Method:    init
// * Signature: ([B)Z
// */
//JNIEXPORT jboolean JNICALL Java_com_tutk_client_FFMPEG_Decoder_init
//        (JNIEnv *env, jobject thiz, jbyteArray jptr) {
//    //init decoder
//    const AVCodec *codec = avcodec_find_decoder((AVCodecID) AV_CODEC_ID_H264);
//    if (0 == codec) {
//        LOGE("unknown codec AV_CODEC_ID_H264\n");
//        return false;
//    }
//    AVCodecContext *decoder = avcodec_alloc_context3(codec);
//    if (0 == decoder) {
//        LOGE("avcodec_alloc_context3 failed!\n");
//        return false;
//    }
//    if (avcodec_open2(decoder, codec, NULL) < 0) {
//        LOGE("avcodec_open2 failed\n");
//        avcodec_free_context(&decoder);
//        return false;
//    }
//    assert(sizeof(void *) <= env->GetArrayLength(jptr));
//    env->SetByteArrayRegion(jptr, 0, sizeof(void *), (const jbyte *) &decoder);
//    return true;
//}
//
//static bool inited_window = false;
//
//class JbyteArrayReleaser {
//public:
//    JbyteArrayReleaser(JNIEnv *e, jbyteArray &a, jbyte *b)
//            : env(e), jarray(a), buff(b) {}
//
//    ~JbyteArrayReleaser() {
//        env->ReleaseByteArrayElements(jarray, buff, 0);
//    }
//
//private:
//    JNIEnv *env;
//    jbyteArray &jarray;
//    jbyte *buff;
//};
//
///*
// * Class:     com_tutk_client_FFMPEG_Decoder
// * Method:    play
// * Signature: ([B[BIIILjava/lang/Object;)V
// */
//JNIEXPORT void JNICALL Java_com_tutk_client_FFMPEG_Decoder_play
//        (JNIEnv *env, jobject thiz, jbyteArray jptr, jbyteArray jframe, jint, jint, jint,
//         jobject jsurface) {
//    AVCodecContext *decoder = 0;
//    env->GetByteArrayRegion(jptr, 0, sizeof(void *), (jbyte *) &decoder);
//    if (0 == decoder) {
//        LOGE("invalid decoder ptr");
//        return;
//    }
//
//    jint raw_len = env->GetArrayLength(jframe);
//    jbyte *raw = env->GetByteArrayElements(jframe, NULL);
//    JbyteArrayReleaser releaser(env, jframe, raw);
//
//    AVPacket pkt;
//    av_init_packet(&pkt);
//    pkt.data = (uint8_t *) raw;
//    pkt.size = raw_len;
//
//    int ret = avcodec_send_packet(decoder, &pkt);
//    AVFrame *frame = av_frame_alloc();
//    Utils::unique_ptr<AVFrame *> frame_releaser(&frame, av_frame_free);
//
//    while (ret >= 0) {
//        ret = avcodec_receive_frame(decoder, frame);
//        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
//            return;
//        } else if (ret < 0) {
//            LOGE("Error during decoding\n");
//            return;
//        }
//
//        // 获取native window
//        ANativeWindow *nativeWindow = ANativeWindow_fromSurface(env, jsurface);
//        if (!inited_window) {
//            // 设置native window的buffer大小,可自动拉伸
//            ANativeWindow_setBuffersGeometry(nativeWindow, frame->width, frame->height,
//                                             WINDOW_FORMAT_RGBA_8888);
//            inited_window = true;
//        }
//
//        const int video_height = frame->height;
//
//        ANativeWindow_Buffer windowBuffer;
//        ANativeWindow_lock(nativeWindow, &windowBuffer, 0);
//        if (0 == windowBuffer.stride) {
//            LOGE("lock window failed");
//            return;
//        }
//        char *dst_data[4];
//        int dst_linesize[4];
//        if (av_image_alloc((uint8_t **) dst_data, dst_linesize, windowBuffer.width,
//                           windowBuffer.height, AV_PIX_FMT_RGBA, 1) < 0) {
//            printf("Could not allocate destination image\n");
//            return;
//        }
//        Utils::unique_ptr<char *, char> dst_data_releaser(&dst_data[0],
//                                                          (void (*)(char *)) av_freep);
//
//        // 由于解码出来的帧格式不是RGBA的,在渲染之前需要进行格式转换
//        struct SwsContext *sws_ctx = sws_getContext(frame->width,
//                                                    frame->height,
//                                                    (AVPixelFormat) frame->format,
//                                                    windowBuffer.width,
//                                                    windowBuffer.height,
//                                                    AV_PIX_FMT_RGBA,
//                                                    0,
//                                                    NULL,
//                                                    NULL,
//                                                    NULL);
//        if (0 == sws_ctx) {
//            LOGE("fuck sws_getContext");
//            return;
//        }
//        sws_scale(sws_ctx, (uint8_t const *const *) frame->data,
//                  frame->linesize, 0, frame->height,
//                  (uint8_t **) dst_data, dst_linesize);
//
//        // 获取stride
//        char *dst = (char *) windowBuffer.bits;
//        int dstStride = windowBuffer.stride * 4;
//        char *src = dst_data[0];
//        int srcStride = dst_linesize[0];
//
//        // 由于window的stride和帧的stride不同,因此需要逐行复制
//        for (int h = 0; h < windowBuffer.height; h++) {
//            memcpy(dst + h * dstStride, src + h * srcStride, srcStride);
//        }
//
//        ANativeWindow_unlockAndPost(nativeWindow);
//
//        sws_freeContext(sws_ctx);
//    }
//}
//
///*
// * Class:     com_tutk_client_FFMPEG_Decoder
// * Method:    deinit
// * Signature: ([B)Z
// */
//JNIEXPORT jboolean JNICALL Java_com_tutk_client_FFMPEG_Decoder_deinit
//        (JNIEnv *env, jobject thiz, jbyteArray jptr) {
//    AVCodecContext *decoder = 0;
//    env->GetByteArrayRegion(jptr, 0, sizeof(void *), (jbyte *) &decoder);
//    if (0 != decoder) {
//        avcodec_free_context(&decoder);
//    }
//    return true;
//}
//
//#ifdef __cplusplus
//}
//#endif