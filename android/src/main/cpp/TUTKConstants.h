//
//  TUTKConstants.h
//  Sample_RDTAPIs
//
//  Created by Pengfei Chen on 16/06/19.
//

#ifndef TUTKConstants_h
#define TUTKConstants_h

#define  TUTK_IOCTL_MAX_DEVICE_SN 32

#define MAX_BUF_SIZE 102400

#define VIDEO_BUF_SIZE    2000000


/**登陆命令及参数**/
typedef enum {
    /** 错误命令定义**/
            TUTK_IOCTL_UNKNOWN_ERROR = -32767,//Cube->APP 未知错误
    TUTK_IOCTL_UNSUPPORTED_COMMAND, //Cube->APP 命令不支持

    /**client login**/
            TUTK_IOCTL_CLIENT_LOGIN = 0, //APP->Cube 手机客户端登陆
    TUTK_IOCTL_CLIENT_LOGIN_RESP, // 手机客户端登陆响应
    TUTK_IOCTL_CLIENT_LOGINOUT, //APP->Cube 手机客户端下线

    /**记录文件回放**/
            TUTK_IOCTL_ENTER_RECORD_PLAY_MODE, // APP->Cube 进入设备回放模式
    TUTK_IOCTL_ENTER_RECORD_PLAY_MODE_RESP,//进入回放模式响应
    TUTK_IOCTL_EXIT_RECORD_PLAY_MODE,//APP->Cube 退出设备回放模式
    TUTK_IOCTL_LIST_RECORD_FILES,//APP->Cube 枚举设备对应时段的记录文件列表
    TUTK_IOCTL_LIST_RECORD_FILES_RESP,//枚举设备对应时段的记录文件列表响应
    TUTK_IOCTL_RECORD_PLAY,//APP->Cube播放记录文件
    TUTK_IOCTL_RECORD_PLAY_RESP,//播放记录文件响应

    /**直播模式**/
            TUTK_IOCTL_ENTER_STREAM_MODE,//APP->Cube 进入设备直播模式
    TUTK_IOCTL_ENTER_STREAM_MODE_RESP,//进入设备直播模式响应
    TUTK_IOCTL_EXIT_STREAM_MODE,//APP->Cube 退出直播模式
    TUTK_IOCTL_STREAM_CLOSED,//Cube->APP Cube发送给APP表示由于某些未知原因导致直播模式被退出了
} NS_ENUM;

/*登陆命令参数*/
struct {
    int tutk_ioctl_version;//协议版本号
    char client_name[65];//客户端用户名
    char password[65];//客户端密码
    int32_t media_chanel;//客户端使用的流媒体通道
} Login;
/*登陆命令响应参数*/
struct {
    char result; //登陆结果 0 =success,1 =(unknown client_name),2 =(invalid password)
} LoginResponse;

/**记录文件播放命令及参数**/

/*记录文件播放相关命令*/
enum RECORD_PLAY_COMMAND {
    TUTK_RECORD_PLAY_START = 0, //开始播放
    TUTK_RECORD_PLAY_STOP,//停止播放
    TUTK_RECORD_PLAY_EXIT,//退出播放
    TUTK_RECORD_PLAY_PAUSE,//暂停
    TUTK_RECORD_PLAY_MOVE,//快进/快退
};
enum ENTER_RECORD_PLAY_RESULT {
    TUTK_ENTER_RECORD_PLAY_SUCCESS = 0,
    TUTK_ENTER_RECORD_PLAY_NO_SUCH_DEVICE = -1,
};

enum ENTER_STREA_MODE_RESULT {
    TUTK_ENTER_STREAM_MODE_SUCCESS = 0,
    TUTK_ENTER_STREAM_MODE_FAILED = -1,
    TUTK_ENTER_STREAM_MODE_NO_SUCH_DEVICE = -2,
    TUTK_ENTER_STREAM_MODE_ALREADY_IN_STREAM = -3,//设备已经在stream模式下

};
/*进入记录文件播放命令参数*/
struct {
    char target_device_sn[TUTK_IOCTL_MAX_DEVICE_SN + 1];//需要进入记录回放模式的设备
} EnterRecordPlayMode;
/*进入记录文件播放命令响应参数*/
struct {
    char result;//进入记录文件播放模式结果 0 =success,others failed
} EnterRecordPlayModeResponse;
/*枚举设备上的记录文件参数*/
struct {
    uint64_t start_time;//记录文件选择区间开始值
    uint64_t end_time;//记录文件选择区间结束值
} ListRecordFiles;
/*枚举设备上的记录文件响应参数*/
struct {
    int total;//设备上符合条件的记录文件总数
    unsigned char index;//响应包下标(可能有多个响应包)
    unsigned char endflag;//枚举是否结束
    unsigned char count;//当前包记录文件总数
    uint64_t record_files[1];//记录文件时间值
} ListRecordFilesResponse;
/*开始播放记录文件参数*/
struct {
    uint64_t record;//要播放的记录文件时间值
} RecordPlayStart;
/*播放记录文件响应参数*/
struct {
    char result; //结果 0 ==success,others failed
    struct {
        int codec_id;//解码器ID
    } video;//视频播放参数
    struct {
        int codec_id;//解码器ID
        int sample_rate;//采样率
        int bit_rate;//比特率
    } audio;
} RecordPlayStartResponse;
/*快进/快退命令参数*/
struct {
    int video_move_pos;//视频流移动到的位置(in time_base)
    int audio_move_pos;//音频流移动到的位置(in time_base)
} RecordPlayMove;
/*快进/快退命令响应参数*/
struct {
    char result;//移动结果 0 = success,others failed
} RecordPlayMoveResponse;
/*暂停音视频流响应参数*/
struct {
    char result;//暂停结果 0 = success,others failed
} RecordPlayPauseResponse;


/* Audio/Video Frame Header Info */
typedef struct _FRAMEINFO {
    unsigned short codec_id;    // Media codec type defined in sys_mmdef.h,
    // MEDIA_CODEC_AUDIO_PCMLE16 for audio,
    // MEDIA_CODEC_VIDEO_H264 for video.
    unsigned char flags;        // Combined with IPC_FRAME_xxx.
    unsigned char cam_index;    // 0 - n

    unsigned char onlineNum;    // number of client connected this device
    unsigned char reserve1[3];

    unsigned int reserve2;    //
    unsigned int timestamp;    // Timestamp of the frame, in milliseconds

    // unsigned int videoWidth;
    // unsigned int videoHeight;

} FRAMEINFO_t;

#endif /* TUTKConstants_h */
