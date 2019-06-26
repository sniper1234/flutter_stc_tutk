//
//  TutkLoctlCommand.h
//  Sample_RDTAPIs
//
//  Created by Pengfei Chen on 16/06/19.
//

#import "TUTKConstants.h"

#define MAX_DATA_SIZE 102400

#pragma pack(push, 1)
struct TutkLoctlCommand {
    int32_t length;
    uint16_t command;
    uint16_t subCommand;
    char data[MAX_DATA_SIZE];
};

/*登陆命令参数*/
struct TutkLoctlCommandDataLogin {
    int32_t tutk_ioctl_version;//协议版本号
    char client_name[65];//客户端用户名
    char password[65];//客户端密码
    int32_t media_chanel;//客户端使用的流媒体通道
};

/*登陆命令响应参数*/
struct TutkLoctlCommandDataLoginResponse {
    char result; //登陆结果 0 =success,1 =(unknown client_name),2 =(invalid password)
};

/*进入记录文件播放命令参数*/
struct TutkLoctlCommandDataVideoPlay {
    char target_device_sn[TUTK_IOCTL_MAX_DEVICE_SN + 1];//需要进入记录回放模式的设备
};
/*进入记录文件播放命令响应参数*/
struct TutkLoctlCommandDataVideoPlayResponse {
    char result;//进入记录文件播放模式结果 0 =success,others failed
};

#pragma pack(pop)

