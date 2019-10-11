//
//  TUTKConstants.h
//  Sample_RDTAPIs
//
//  Created by Pengfei Chen on 16/06/19.
//

#ifndef TUTKConstants_h
#define TUTKConstants_h

#define  TUTK_IOCTL_MAX_DEVICE_SN 32

 

/**登陆命令及参数**/
typedef NS_ENUM(NSInteger, TUTK_IOCTL_TYPE)  {
    /** tutk command error definition**/
    TUTK_IOCTL_UNKNOWN_ERROR= -32767,//unknown error happens while device response to app
    TUTK_IOCTL_UNSUPPORTED_COMMAND = -1, //the command is not supported by the coomand's target

    /**client login**/
    TUTK_IOCTL_CLIENT_LOGIN = 0, // used by app to login into a scene cube
    TUTK_IOCTL_CLIENT_LOGIN_RESP = 1, // used by device to  tell app if app can login into device or not
    TUTK_IOCTL_CLIENT_LOGINOUT = 2, // used by app to login out from a scene cube

    /**record play back**/
    TUTK_IOCTL_ENTER_RECORD_PLAY_MODE = 3, // used by app to enter a record play mode
    TUTK_IOCTL_ENTER_RECORD_PLAY_MODE_RESP = 4,//used by device to notify app that device has entered record play or not
    TUTK_IOCTL_EXIT_RECORD_PLAY_MODE = 5,// used by app to exit a record play mode
    TUTK_IOCTL_LIST_RECORD_FILES = 6,//used by app to list record play files in target device
    TUTK_IOCTL_LIST_RECORD_FILES_RESP = 7,//used by device to response record file list to app
    TUTK_IOCTL_RECORD_PLAY = 8,//a record play parent command,the actual function decided by child command
    TUTK_IOCTL_RECORD_PLAY_RESP = 9,//used by device to transfer some play infomation,eg. movie's width&height ,audio's sample rate ,vedio/audio codec id...

    /**live stream**/
    TUTK_IOCTL_ENTER_STREAM_MODE = 10,//used by app to start a live stream from device
    TUTK_IOCTL_ENTER_STREAM_MODE_RESP = 11,
    TUTK_IOCTL_EXIT_STREAM_MODE = 12,//used by app to exit the live stream from device
    TUTK_IOCTL_STREAM_CLOSED = 13,//used by device to notify client that stream has closed on unknown reason

    /* media content */
    TUTK_IOCTL_MEDIA_CONTENT = 14,
};

/*登陆命令参数*/
//struct {
//    int tutk_ioctl_version;//协议版本号
//    char client_name[65];//客户端用户名
//    char password[65];//客户端密码
//    int32_t media_chanel;//客户端使用的流媒体通道
//} Login;
///*登陆命令响应参数*/
//struct {
//    char result; //登陆结果 0 =success,1 =(unknown client_name),2 =(invalid password)
//} LoginResponse;
//
///**记录文件播放命令及参数**/
//
///*记录文件播放相关命令*/
//enum RECORD_PLAY_COMMAND
//{
//    TUTK_RECORD_PLAY_START = 0, //开始播放
//    TUTK_RECORD_PLAY_STOP,//停止播放
//    TUTK_RECORD_PLAY_EXIT,//退出播放
//    TUTK_RECORD_PLAY_PAUSE,//暂停
//    TUTK_RECORD_PLAY_MOVE,//快进/快退
//};
//enum ENTER_RECORD_PLAY_RESULT
//{
//    TUTK_ENTER_RECORD_PLAY_SUCCESS = 0,
//    TUTK_ENTER_RECORD_PLAY_NO_SUCH_DEVICE = -1,
//};
//
//enum ENTER_STREA_MODE_RESULT
//{
//    TUTK_ENTER_STREAM_MODE_SUCCESS = 0,
//    TUTK_ENTER_STREAM_MODE_FAILED = -1,
//    TUTK_ENTER_STREAM_MODE_NO_SUCH_DEVICE = -2,
//    TUTK_ENTER_STREAM_MODE_ALREADY_IN_STREAM = -3,//设备已经在stream模式下
//    
//};
///*进入记录文件播放命令参数*/
//struct {
//    char target_device_sn[TUTK_IOCTL_MAX_DEVICE_SN+1];//需要进入记录回放模式的设备
//}EnterRecordPlayMode;
///*进入记录文件播放命令响应参数*/
//struct {
//    char result;//进入记录文件播放模式结果 0 =success,others failed
//}EnterRecordPlayModeResponse;
///*枚举设备上的记录文件参数*/
//struct
//{
//    uint64_t start_time;//记录文件选择区间开始值
//    uint64_t end_time;//记录文件选择区间结束值
//}ListRecordFiles;
///*枚举设备上的记录文件响应参数*/
//struct
//{
//    int  total;//设备上符合条件的记录文件总数
//    unsigned char index;//响应包下标(可能有多个响应包)
//    unsigned char endflag;//枚举是否结束
//    unsigned char count;//当前包记录文件总数
//    uint64_t record_files[1];//记录文件时间值
//}ListRecordFilesResponse;
///*开始播放记录文件参数*/
//struct
//{
//    uint64_t record;//要播放的记录文件时间值
//}RecordPlayStart;
///*播放记录文件响应参数*/
//struct {
//    char result; //结果 0 ==success,others failed
//    struct{
//        int codec_id;//解码器ID
//    }video;//视频播放参数
//    struct{
//        int codec_id;//解码器ID
//        int sample_rate;//采样率
//        int bit_rate;//比特率
//    }audio;
//}RecordPlayStartResponse;
///*快进/快退命令参数*/
//struct {
//    int video_move_pos;//视频流移动到的位置(in time_base)
//    int audio_move_pos;//音频流移动到的位置(in time_base)
//}RecordPlayMove;
///*快进/快退命令响应参数*/
//struct {
//    char result;//移动结果 0 = success,others failed
//}RecordPlayMoveResponse;
///*暂停音视频流响应参数*/
//struct {
//    char result;//暂停结果 0 = success,others failed
//}RecordPlayPauseResponse;


#endif /* TUTKConstants_h */
