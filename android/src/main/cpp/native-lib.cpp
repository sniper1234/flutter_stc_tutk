#include <jni.h>
#include <string>
#include <unistd.h>
#include "TUTKConstants.h"
#include "TutkLoctlCommand.h"
#include "IOTCAPIs.h"
#include "AVAPIs.h"
#include <android/log.h>
#include "com_tutk_client_FFMPEG_Decoder.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>
#include <android/log.h>
#include <jni.h>
#include <android/bitmap.h>
#include <cstdio>


//定义输出的TAG
const char *LOG_TGA = "LOG_TGA";

extern "C"
JNIEXPORT jint JNICALL
Java_com_tutk_IOTC_TutkLoctlCommand_login(JNIEnv *env, jclass type, jint sid, jint mediaChannel,
                                          jstring userName_, jstring password_) {
    const char *userName = env->GetStringUTFChars(userName_, 0);
    const char *password = env->GetStringUTFChars(password_, 0);

    env->ReleaseStringUTFChars(userName_, userName);
    env->ReleaseStringUTFChars(password_, password);

    char buf[MAX_BUF_SIZE];

    char redBuf[1400];

    struct TutkLoctlCommand loginCommand{};
    struct TutkLoctlCommandDataLogin loginCommandData{};
    int dataLength = sizeof(loginCommand) - MAX_DATA_SIZE + sizeof(loginCommandData);

    loginCommand.command = 0;
    loginCommand.length = dataLength;
    loginCommandData.tutk_ioctl_version = 1;
    loginCommandData.media_chanel = mediaChannel;


    strcpy((char *) loginCommandData.client_name, userName);
    strcpy((char *) loginCommandData.password, password);

    memcpy(loginCommand.data, &loginCommandData, sizeof(loginCommandData));

    memcpy(buf, &loginCommand, dataLength);

    int ret = IOTC_Session_Write_Reliable_NB(sid, buf, dataLength, 0);
    if (ret < 0) {
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA,
                            "IOTC_Session_Write_Reliable_NB send cmd failed[%d]!!\n", ret);
        IOTC_Session_Close(sid);
        return -1;
    }

    printf("AVStream Client Start");

    IOTC_Session_Write_Reliable_NB(sid, redBuf, 1400, 0);


    struct st_SInfo Sinfo;
    ret = IOTC_Session_Check(sid, &Sinfo);

    if (ret >= 0) {
        if (Sinfo.Mode == 0)
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA, "Device is from %s:%d[%s] Mode=P2P\n",
                                Sinfo.RemoteIP,
                                Sinfo.RemotePort,
                                Sinfo.UID);
        else if (Sinfo.Mode == 1)
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA, "Device is from %s:%d[%s] Mode=RLY\n",
                                Sinfo.RemoteIP,
                                Sinfo.RemotePort,
                                Sinfo.UID);
        else if (Sinfo.Mode == 2)
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA, "Device is from %s:%d[%s] Mode=LAN\n",
                                Sinfo.RemoteIP,
                                Sinfo.RemotePort,
                                Sinfo.UID);
    }

    unsigned int srvType = 0;
    int avIndex = avClientStart(sid, userName, password, 30, &srvType, mediaChannel);
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA, "STEP 4: call avClientStart(%d).......\n",
                        avIndex);

    if (avIndex < 0) {
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA, "avClientStart failed[%d]\n", avIndex);
        return -1;
    }

    return avIndex;
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_tutk_IOTC_TutkLoctlCommand_startLiveVideo(JNIEnv *env, jclass type, jint sid,
                                                   jint mediaChannel) {

    int ret = 0;

    int SID = (int) sid;

    char buf[MAX_BUF_SIZE];

    struct TutkLoctlCommand videoPlayCommand;
    struct TutkLoctlCommandDataVideoPlay videoPlayCommandData;
    int dataLength = sizeof(videoPlayCommand) - MAX_DATA_SIZE + sizeof(videoPlayCommandData);

    videoPlayCommand.command = TUTK_IOCTL_ENTER_STREAM_MODE;
    videoPlayCommand.length = dataLength;
    strcpy(videoPlayCommandData.target_device_sn, "T39S24CTY4TZ");

    memcpy(videoPlayCommand.data, &videoPlayCommandData, sizeof(videoPlayCommandData));

    memcpy(buf, &videoPlayCommand, dataLength);

    ret = IOTC_Session_Write_Reliable_NB(SID, buf, dataLength, 0);
    if (ret < 0) {
        printf("IOTC_Session_Write_Reliable_NB send cmd failed[%d]!!\n", ret);
        IOTC_Session_Close(SID);
        return ret;
    }
    return ret;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_tutk_IOTC_TutkLoctlCommand_stopAv(JNIEnv *env, jclass type, jint sid,
                                           jint currentAvIndex) {
    avClientStop(currentAvIndex);
    printf("avClientStop OK");
    printf("IOTC_Session_Close OK");
    avDeInitialize();
    printf("StreamClient exit...");
}

extern "C"
JNIEXPORT void JNICALL
Java_com_tutk_IOTC_TutkLoctlCommand_receiveVideoThread(JNIEnv *env, jclass type, jint avIndex) {

    char *buf = static_cast<char *>(malloc(VIDEO_BUF_SIZE));
    unsigned int frmNo;
    int actualFrameSize = 0, expectedFrameSize = 0;
    int actualInfoSize = 0;
    int ret;
    FRAMEINFO_t frameInfo;

    while (1) {
        ret = avRecvFrameData2(avIndex, buf, VIDEO_BUF_SIZE, &actualFrameSize, &expectedFrameSize,
                               (char *) &frameInfo, sizeof(FRAMEINFO_t), &actualInfoSize, &frmNo);

        if (ret == AV_ER_DATA_NOREADY) {
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA, "Video data not ready");
            usleep(30000);
            continue;
        } else if (ret == AV_ER_LOSED_THIS_FRAME) {
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA, "Lost video frame NO[%d]", frmNo);
            continue;
        } else if (ret == AV_ER_INCOMPLETE_FRAME) {
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA, "Incomplete video frame NO[%d]", frmNo);
            continue;
        } else if (ret == AV_ER_SESSION_CLOSE_BY_REMOTE) {
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA,
                                "[thread_ReceiveVideo] AV_ER_SESSION_CLOSE_BY_REMOTE");
            break;
        } else if (ret == AV_ER_REMOTE_TIMEOUT_DISCONNECT) {
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA,
                                "[thread_ReceiveVideo] AV_ER_REMOTE_TIMEOUT_DISCONNECT");
            break;
        } else if (ret == IOTC_ER_INVALID_SID) {
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA,
                                "[thread_ReceiveVideo] Session cant be used anymore");
            break;
        }
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TGA,
                            "[thread_ReceiveVideo]  got an IFrame, draw it");
    }
    free(buf);
    printf("[thread_ReceiveVideo] thread exit");
//    return;
}


static const char *TAG = "ffmpeg";
#define LOGI(fmt, args...) __android_log_print(ANDROID_LOG_INFO,  TAG, fmt, ##args)
#define LOGD(fmt, args...) __android_log_print(ANDROID_LOG_DEBUG, TAG, fmt, ##args)
#define LOGE(fmt, args...) __android_log_print(ANDROID_LOG_ERROR, TAG, fmt, ##args)

extern "C" {
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/rational.h"
#include "libavutil/avutil.h"
#include "libavutil/imgutils.h"
#include "libavutil/frame.h"
#include "libswscale/swscale.h"
}

#include "utils.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Class:     com_tutk_client_FFMPEG_Decoder
 * Method:    init
 * Signature: ([B)Z
 */
JNIEXPORT jboolean JNICALL Java_com_tutk_client_FFMPEG_Decoder_init
        (JNIEnv *env, jobject thiz, jbyteArray jptr) {
    //init decoder
    const AVCodec *codec = avcodec_find_decoder((AVCodecID) AV_CODEC_ID_H264);
    if (0 == codec) {
        LOGE("unknown codec AV_CODEC_ID_H264\n");
        return false;
    }
    AVCodecContext *decoder = avcodec_alloc_context3(codec);
    if (0 == decoder) {
        LOGE("avcodec_alloc_context3 failed!\n");
        return false;
    }
    if (avcodec_open2(decoder, codec, NULL) < 0) {
        LOGE("avcodec_open2 failed\n");
        avcodec_free_context(&decoder);
        return false;
    }
    assert(sizeof(void *) <= env->GetArrayLength(jptr));
    env->SetByteArrayRegion(jptr, 0, sizeof(void *), (const jbyte *) &decoder);
    return true;
}

static bool inited_window = false;

class JbyteArrayReleaser {
public:
    JbyteArrayReleaser(JNIEnv *e, jbyteArray &a, jbyte *b)
            : env(e), jarray(a), buff(b) {}

    ~JbyteArrayReleaser() {
        env->ReleaseByteArrayElements(jarray, buff, 0);
    }

private:
    JNIEnv *env;
    jbyteArray &jarray;
    jbyte *buff;
};

/*
 * Class:     com_tutk_client_FFMPEG_Decoder
 * Method:    play
 * Signature: ([B[BIIILjava/lang/Object;)V
 */
JNIEXPORT void JNICALL Java_com_tutk_client_FFMPEG_Decoder_play
        (JNIEnv *env, jobject thiz, jbyteArray jptr, jbyteArray jframe, jint, jint, jint,
         jobject jsurface) {
    AVCodecContext *decoder = 0;
    env->GetByteArrayRegion(jptr, 0, sizeof(void *), (jbyte *) &decoder);
    if (0 == decoder) {
        LOGE("invalid decoder ptr");
        return;
    }

    jint raw_len = env->GetArrayLength(jframe);
    jbyte *raw = env->GetByteArrayElements(jframe, NULL);
    JbyteArrayReleaser releaser(env, jframe, raw);

    AVPacket pkt;
    av_init_packet(&pkt);
    pkt.data = (uint8_t *) raw;
    pkt.size = raw_len;

    int ret = avcodec_send_packet(decoder, &pkt);
    AVFrame *frame = av_frame_alloc();
    Utils::unique_ptr<AVFrame *> frame_releaser(&frame, av_frame_free);

    while (ret >= 0) {
        ret = avcodec_receive_frame(decoder, frame);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
            return;
        } else if (ret < 0) {
            LOGE("Error during decoding\n");
            return;
        }

        // 获取native window
        ANativeWindow *nativeWindow = ANativeWindow_fromSurface(env, jsurface);
        if (!inited_window) {
            // 设置native window的buffer大小,可自动拉伸
            ANativeWindow_setBuffersGeometry(nativeWindow, frame->width, frame->height,
                                             WINDOW_FORMAT_RGBA_8888);
            inited_window = true;
        }

        const int video_height = frame->height;

        ANativeWindow_Buffer windowBuffer;
        ANativeWindow_lock(nativeWindow, &windowBuffer, 0);
        if (0 == windowBuffer.stride) {
            LOGE("lock window failed");
            return;
        }
        char *dst_data[4];
        int dst_linesize[4];
        if (av_image_alloc((uint8_t **) dst_data, dst_linesize, windowBuffer.width,
                           windowBuffer.height, AV_PIX_FMT_RGBA, 1) < 0) {
            printf("Could not allocate destination image\n");
            return;
        }
        Utils::unique_ptr<char *, char> dst_data_releaser(&dst_data[0],
                                                          (void (*)(char *)) av_freep);

        // 由于解码出来的帧格式不是RGBA的,在渲染之前需要进行格式转换
        struct SwsContext *sws_ctx = sws_getContext(frame->width,
                                                    frame->height,
                                                    (AVPixelFormat) frame->format,
                                                    windowBuffer.width,
                                                    windowBuffer.height,
                                                    AV_PIX_FMT_RGBA,
                                                    0,
                                                    NULL,
                                                    NULL,
                                                    NULL);
        if (0 == sws_ctx) {
            LOGE("fuck sws_getContext");
            return;
        }
        sws_scale(sws_ctx, (uint8_t const *const *) frame->data,
                  frame->linesize, 0, frame->height,
                  (uint8_t **) dst_data, dst_linesize);

        // 获取stride
        char *dst = (char *) windowBuffer.bits;
        int dstStride = windowBuffer.stride * 4;
        char *src = dst_data[0];
        int srcStride = dst_linesize[0];

        // 由于window的stride和帧的stride不同,因此需要逐行复制
        for (int h = 0; h < windowBuffer.height; h++) {
            memcpy(dst + h * dstStride, src + h * srcStride, srcStride);
        }

        ANativeWindow_unlockAndPost(nativeWindow);

        sws_freeContext(sws_ctx);
    }
}

/*
 * Class:     com_tutk_client_FFMPEG_Decoder
 * Method:    deinit
 * Signature: ([B)Z
 */
JNIEXPORT jboolean JNICALL Java_com_tutk_client_FFMPEG_Decoder_deinit
        (JNIEnv *env, jobject thiz, jbyteArray jptr) {
    AVCodecContext *decoder = 0;
    env->GetByteArrayRegion(jptr, 0, sizeof(void *), (jbyte *) &decoder);
    if (0 != decoder) {
        avcodec_free_context(&decoder);
    }
    return true;
}

#ifdef __cplusplus
}
#endif