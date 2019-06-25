//
//  Client.m
//  Sample_AVAPIs
//
//  Created by tutk on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Client.h"
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <unistd.h>
#import <time.h>
#import <pthread.h>
#import "include/IOTCAPIs.h"
#import "include/RDTAPIs.h"

#import "include/AVAPIs.h"
#import "include/AVIOCTRLDEFs.h"
#import "include/AVFRAMEINFO.h"
#import <sys/time.h>
#import <pthread.h>

#import "TUTKConstants.h"
#import "TutkLoctlCommand.h"

#define AUDIO_BUF_SIZE    1024
#define VIDEO_BUF_SIZE    2000000

@interface Client() {

}

@property(nonatomic, copy) NSString* uid;
@property(nonatomic) int sid;
@property(nonatomic) int mediaChannel;
@property(nonatomic) int currentAvIndex;
@property(nonatomic) NSThread* videoThread;

@end

@implementation Client

#define _UID "ABXG1TRYG5PRSD1R111A"
#define DUMP_FILE 0
#define FileNum 2

#define START_STRING "Start"
#define RDT_WAIT_TIME_MS 30000
#define MAX_BUF_SIZE 102400
#define MAX_MEM_USE 128000

- (void) initialize {
    // initialize iotc
    int ret = IOTC_Initialize2(0);
    
    // alloc 3 sessions for video and two-way audio
    avInitialize(8);
    
    if(ret != IOTC_ER_NoERROR)
    {
        NSLog(@"IOTC_Initialize error!!\n");
        return ;
    }
    
    // connect iotc sesstion
    int SID, media_chanel = 0;
    while(1)
    {
        SID = IOTC_Get_SessionID();
        if (SID < 0)
        {
            NSLog(@"IOTC_Get_SessionID error code [%d]\n", SID);
            return;
        }
        ret = IOTC_Connect_ByUID_Parallel(_UID, SID);
        NSLog(@"Step 2: call IOTC_Connect_ByUID_Parallel(%s) ret = %d\n", _UID, ret);
        if(ret < 0)
        {
            NSLog(@"p2pAPIs_Client connect failed...!!\n");
            return ;
        }
        ret = IOTC_Session_Channel_ON(SID, 0);
        if(ret < 0)
        {
            printf("p2pAPIs_Client open channel 0 failed...!!\n");
            return ;
        }
        // Get free channel
        media_chanel = IOTC_Session_Get_Free_Channel((int)self.sid);
        if(media_chanel < 0) {
            printf("IOTC_Session_Get_Free_Channel get free channel failed...!!\n");
            return ;
        } else {
            printf("Step 3: call IOTC_Session_Get_Free_Channel(%ld) ret = %d\n", (long)self.sid, media_chanel);
            break;
        }
    }
    
    self.mediaChannel = media_chanel;
    self.sid = SID;
}

- (void) login {
    //|Length|TUTK_IOCTL_TYPE|根据主命令变化|命令数据|
    //TUTK_IOCTL_CLIENT_LOGIN = 0
    int SID = (int)self.sid;
    
    char buf[MAX_BUF_SIZE];
    
    struct TutkLoctlCommand loginCommand;
    struct TutkLoctlCommandDataLogin loginCommandData;
    int dataLength = sizeof(loginCommand) - MAX_DATA_SIZE + sizeof(loginCommandData);
    
    loginCommand.command = TUTK_IOCTL_CLIENT_LOGIN;
    loginCommand.length = dataLength;
    loginCommandData.tutk_ioctl_version = 1;
    loginCommandData.media_chanel = (int)self.mediaChannel;
    
    strcpy((char*)loginCommandData.client_name,"admin");
    strcpy((char*)loginCommandData.password, "888888");

    memcpy(loginCommand.data, &loginCommandData, sizeof(loginCommandData));
    
    memcpy(buf, &loginCommand, dataLength);

    int ret = IOTC_Session_Write_Reliable_NB(SID, buf, dataLength, 0);
    if(ret < 0)
    {
        printf("IOTC_Session_Write_Reliable_NB send cmd failed[%d]!!\n", ret);
        IOTC_Session_Close(SID);
        return;
    }
    
    NSLog(@"AVStream Client Start");
    
    struct st_SInfo Sinfo;
    ret = IOTC_Session_Check(SID, &Sinfo);
    
    if (ret >= 0)
    {
        if(Sinfo.Mode == 0)
            printf("Device is from %s:%d[%s] Mode=P2P\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
        else if (Sinfo.Mode == 1)
            printf("Device is from %s:%d[%s] Mode=RLY\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
        else if (Sinfo.Mode == 2)
            printf("Device is from %s:%d[%s] Mode=LAN\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
    }
    
    unsigned int srvType = 0;
    int avIndex = avClientStart(SID, "admin", "888888", 30, &srvType, self.mediaChannel);
    printf("STEP 4: call avClientStart(%d).......\n", avIndex);
    
    if(avIndex < 0)
    {
        printf("avClientStart failed[%d]\n", avIndex);
        return;
    }
    
    self.currentAvIndex = avIndex;
    [self startReceiveVideoThread];
//    if (start_ipcam_stream(avIndex)>0)
//    {
//        
////        pthread_t ThreadVideo_ID, ThreadAudio_ID;
////        pthread_create(&ThreadVideo_ID, NULL, &thread_ReceiveVideo, (void *)&avIndex);
////        pthread_create(&ThreadAudio_ID, NULL, &thread_ReceiveAudio, (void *)&avIndex);
////        pthread_join(ThreadVideo_ID, NULL);
////        pthread_join(ThreadAudio_ID, NULL);
//    } else {
//        // close session
//    }
}

- (void) startLiveVideo {
    int ret = 0;
    
    //|Length|TUTK_IOCTL_TYPE|根据主命令变化|命令数据|
    //TUTK_IOCTL_CLIENT_LOGIN = 0
    int SID = (int)self.sid;
    
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
    if(ret < 0)
    {
        printf("IOTC_Session_Write_Reliable_NB send cmd failed[%d]!!\n", ret);
        IOTC_Session_Close(SID);
        return;
    }
    
    NSLog(@"AVStream Client Start");
    
    
}

- (void) stopAV {
    avClientStop(self.currentAvIndex);
    NSLog(@"avClientStop OK");
    IOTC_Session_Close(self.sid);
    NSLog(@"IOTC_Session_Close OK");
    avDeInitialize();
    IOTC_DeInitialize();
    
    NSLog(@"StreamClient exit...");
}

unsigned int _getTickCount() {
    
    struct timeval tv;
    
    if (gettimeofday(&tv, NULL) != 0)
        return 0;
    
    return (unsigned int)(tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

void *thread_ReceiveAudio(void *arg)
{
    NSLog(@"[thread_ReceiveAudio] Starting...");
    
    int avIndex = *(int *)arg;
    char buf[AUDIO_BUF_SIZE];
    unsigned int frmNo;
    int ret;
    FRAMEINFO_t frameInfo;
    
    while (1)
    {
        ret = avCheckAudioBuf(avIndex);
        if (ret < 0) break;
        if (ret < 3) // determined by audio frame rate
        {
            usleep(120000);
            continue;
        }
        
        ret = avRecvAudioData(avIndex, buf, AUDIO_BUF_SIZE, (char *)&frameInfo, sizeof(FRAMEINFO_t), &frmNo);
        
        if(ret == AV_ER_SESSION_CLOSE_BY_REMOTE)
        {
            NSLog(@"[thread_ReceiveAudio] AV_ER_SESSION_CLOSE_BY_REMOTE");
            break;
        }
        else if(ret == AV_ER_REMOTE_TIMEOUT_DISCONNECT)
        {
            NSLog(@"[thread_ReceiveAudio] AV_ER_REMOTE_TIMEOUT_DISCONNECT");
            break;
        }
        else if(ret == IOTC_ER_INVALID_SID)
        {
            NSLog(@"[thread_ReceiveAudio] Session cant be used anymore");
            break;
        }
        else if (ret == AV_ER_LOSED_THIS_FRAME)
        {
            continue;
        }
        
        // Now the data is ready in audioBuffer[0 ... ret - 1]
        // Do something here
    }
    
    NSLog(@"[thread_ReceiveAudio] thread exit");
    return 0;
}

-(void) receiveVideoThread
{
    NSLog(@"[thread_ReceiveVideo] Starting...");
    
    int avIndex = self.currentAvIndex;
    char *buf = malloc(VIDEO_BUF_SIZE);
    unsigned int frmNo;
    int actualFrameSize=0, expectedFrameSize=0;
    int actualInfoSize=0;
    int ret;
    FRAMEINFO_t frameInfo;
    
    while (1)
    {
        ret = avRecvFrameData2(avIndex, buf, VIDEO_BUF_SIZE, &actualFrameSize, &expectedFrameSize, (char *)&frameInfo, sizeof(FRAMEINFO_t), &actualInfoSize, &frmNo);
        
        if(ret == AV_ER_DATA_NOREADY)
        {
            NSLog(@"Video data not ready");
            usleep(30000);
            continue;
        }
        else if(ret == AV_ER_LOSED_THIS_FRAME)
        {
            NSLog(@"Lost video frame NO[%d]", frmNo);
            continue;
        }
        else if(ret == AV_ER_INCOMPLETE_FRAME)
        {
            NSLog(@"Incomplete video frame NO[%d]", frmNo);
            continue;
        }
        else if(ret == AV_ER_SESSION_CLOSE_BY_REMOTE)
        {
            NSLog(@"[thread_ReceiveVideo] AV_ER_SESSION_CLOSE_BY_REMOTE");
            break;
        }
        else if(ret == AV_ER_REMOTE_TIMEOUT_DISCONNECT)
        {
            NSLog(@"[thread_ReceiveVideo] AV_ER_REMOTE_TIMEOUT_DISCONNECT");
            break;
        }
        else if(ret == IOTC_ER_INVALID_SID)
        {
            NSLog(@"[thread_ReceiveVideo] Session cant be used anymore");
            break;
        }
        
//        if(frameInfo.flags == IPC_FRAME_FLAG_IFRAME)
//        {
//            // got an IFrame, draw it.
//            NSLog(@"[thread_ReceiveVideo]  got an IFrame, draw it");
//        }
        
        NSLog(@"[thread_ReceiveVideo]  got an IFrame, draw it");
        [self.delegate didReceiveVideoFrame:avIndex frameBuffer:buf frameSize:actualFrameSize frameNumber:frmNo];
    }
    free(buf);
    NSLog(@"[thread_ReceiveVideo] thread exit");
    return;
}

int start_ipcam_stream (int avIndex) {
    
    int ret;
    unsigned short val = 0;
    
    if ((ret = avSendIOCtrl(avIndex, IOTYPE_INNER_SND_DATA_DELAY, (char *)&val, sizeof(unsigned short)) < 0))
    {
        NSLog(@"start_ipcam_stream_failed[%d]", ret);
        return 0;
    }
    
    SMsgAVIoctrlAVStream ioMsg;
    memset(&ioMsg, 0, sizeof(SMsgAVIoctrlAVStream));
    if ((ret = avSendIOCtrl(avIndex, IOTYPE_USER_IPCAM_START, (char *)&ioMsg, sizeof(SMsgAVIoctrlAVStream)) < 0))
    {
        NSLog(@"start_ipcam_stream_failed[%d]", ret);
        return 0;
    }
    
    if ((ret = avSendIOCtrl(avIndex, IOTYPE_USER_IPCAM_AUDIOSTART, (char *)&ioMsg, sizeof(SMsgAVIoctrlAVStream)) < 0))
    {
        NSLog(@"start_ipcam_stream_failed[%d]", ret);
        return 0;
    }
    
    return 1;
}

-(void) videoThreadProcess {
    int ret = 0, SID;
    NSString* UID = self.uid;
    
    NSLog(@"AVStream Client Start");
    
    // alloc 4 sessions for video and two-way audio
    avInitialize(4);
    
    SID = IOTC_Get_SessionID();
    if (SID < 0)
    {
        NSLog(@"IOTC_Get_SessionID error [%d]", SID);
        return;
    }
    ret = IOTC_Connect_ByUID_Parallel((char *)[UID UTF8String], SID);
    if (ret < 0)
    {
        NSLog(@"IOTC_Connect_ByUID_Parallel error [%d]", ret);
        return;
    }
    
    printf("Step 2: call IOTC_Connect_ByUID_Parallel(%s) ret(%d).......\n", [UID UTF8String], ret);
    struct st_SInfo Sinfo;
    ret = IOTC_Session_Check(SID, &Sinfo);
    
    if (ret >= 0)
    {
        if(Sinfo.Mode == 0)
            printf("Device is from %s:%d[%s] Mode=P2P\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
        else if (Sinfo.Mode == 1)
            printf("Device is from %s:%d[%s] Mode=RLY\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
        else if (Sinfo.Mode == 2)
            printf("Device is from %s:%d[%s] Mode=LAN\n",Sinfo.RemoteIP, Sinfo.RemotePort, Sinfo.UID);
    }
    
    unsigned long srvType;
    int avIndex = avClientStart(SID, "admin", "888888", 20000, &srvType, 0);
    printf("Step 3: call avClientStart(%d).......\n", avIndex);
    
    if(avIndex < 0)
    {
        printf("avClientStart failed[%d]\n", avIndex);
        return;
    }
    
    if (start_ipcam_stream(avIndex)>0)
    {
        [self startReceiveVideoThread];
        
//        pthread_t ThreadVideo_ID, ThreadAudio_ID;
//        pthread_create(&ThreadVideo_ID, NULL, &thread_ReceiveVideo, (void *)&avIndex);
//        pthread_create(&ThreadAudio_ID, NULL, &thread_ReceiveAudio, (void *)&avIndex);
//        pthread_join(ThreadVideo_ID, NULL);
//        pthread_join(ThreadAudio_ID, NULL);
    }
    
//    avClientStop(avIndex);
//    NSLog(@"avClientStop OK");
//    IOTC_Session_Close(SID);
//    NSLog(@"IOTC_Session_Close OK");
//    avDeInitialize();
//    IOTC_DeInitialize();
//
//    NSLog(@"StreamClient exit...");
    
}


/**
 *  使用init方法显式创建线程
 */
- (void)startReceiveVideoThread {
    // 创建线程
    self.videoThread = [[NSThread alloc] initWithTarget:self selector:@selector(receiveVideoThread) object:nil];
    // 设置线程名
    [self.videoThread setName:@"videoPlayThread"];
    // 设置优先级 优先级从0到1 1最高
    [self.videoThread setThreadPriority:0.9];
    // 启动线程
    [self.videoThread start];
}



@end
