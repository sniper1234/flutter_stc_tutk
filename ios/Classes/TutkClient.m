//
//  TutkClient.m
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 23/06/19.
//

#import "TutkClient.h"
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
#define MAX_BUF_SIZE 102400
#define FRAME_BUF_SIZE    5000000

@interface TutkClient()

@property(nonatomic, copy) NSString* uid;
@property(nonatomic, copy) NSString* deviceSN;
@property(nonatomic) int sid;
@property(nonatomic) int mediaChannel;
@property(nonatomic) int currentAvIndex;
@property(nonatomic) NSThread* videoThread;

@property(nonatomic) NSMutableDictionary* channelInfo;

@property(nonatomic) uint frameNo;

@property(nonatomic) NSString* filePath;
@end

@implementation TutkClient

- (void) initialize:(NSString*) uid {
    // initialize iotc
    int ret = IOTC_Initialize2(0);
    const char* UID = [uid UTF8String];
    
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
        ret = IOTC_Connect_ByUID_Parallel(UID, SID);
        NSLog(@"Step 2: call IOTC_Connect_ByUID_Parallel(%s) ret = %d\n", UID, ret);
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

- (void) requestLiveVideo:(NSString*) deviceSN {
    
    self.filePath = [NSString stringWithFormat:@"%@-%lld", [[NSBundle mainBundle] bundlePath], (int64_t)[NSDate date].timeIntervalSince1970];
    
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
    
    strcpy(videoPlayCommandData.target_device_sn, [deviceSN UTF8String]);
    
    memcpy(videoPlayCommand.data, &videoPlayCommandData, sizeof(videoPlayCommandData));
    
    memcpy(buf, &videoPlayCommand, dataLength);
    
    ret = IOTC_Session_Write_Reliable_NB(SID, buf, dataLength, 0);
    if(ret < 0)
    {
        printf("IOTC_Session_Write_Reliable_NB send cmd failed[%d]!!\n", ret);
        IOTC_Session_Close(SID);
        return;
    }
    
    self.deviceSN = deviceSN;
    NSLog(@"AVStream Client Start");
}

-(void) receiveVideoThread
{
    NSLog(@"[thread_ReceiveVideo] Start Receiving...");
    
    int avIndex = self.currentAvIndex;
    char *buf = malloc(VIDEO_BUF_SIZE);
    char* frameBuffer = malloc(FRAME_BUF_SIZE);
    unsigned int frmNo = 0;
    int actualFrameSize=0, expectedFrameSize=0;
    int actualInfoSize=0;
    int ret;
    FRAMEINFO_t frameInfo;
    int frameBufferIndex = 0;
    self.frameNo = 0;
    
    while (![self.videoThread isCancelled])
    {
        ret = avRecvFrameData2(avIndex, buf, VIDEO_BUF_SIZE, &actualFrameSize, &expectedFrameSize, (char *)&frameInfo, sizeof(FRAMEINFO_t), &actualInfoSize, &frmNo);
        
        if(ret == AV_ER_DATA_NOREADY)
        {
            //NSLog(@"Video data not ready");X
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
        
       // NSLog(@"[thread_ReceiveVideo]  got an IFrame, draw it");
        
//        NSData* frameData = [[NSData alloc] initWithBytes:buf length:actualFrameSize];
//        NSMutableData* allData = [NSMutableData dataWithContentsOfFile:self.filePath options:NSDataReadingUncached error:nil];
//        if (allData == nil) {
//            allData = [[NSMutableData alloc] init];
//        }
//        [allData appendData:frameData];
//        [allData writeToFile:self.filePath atomically:true];
        
        // Put data into frame buffer
        memcpy((char*)(frameBuffer + frameBufferIndex), buf, actualFrameSize);
        frameBufferIndex += actualFrameSize;
        
        // Extract frame from frame buffer
        int frameStartIdex = -1;
        int frameEndIndex = -1;
        for (int i = 0; i < frameBufferIndex; i++) {
            if ((int8_t)frameBuffer[i] == 0x00 && (int8_t)frameBuffer[i+1] == 0x00 && (int8_t)frameBuffer[i+2] == 0x00 && (int8_t)frameBuffer[i+3] == 0x01) {
                
                int nalu_type = (frameBuffer[4] & 0x1F);
                if (nalu_type == 5) {
                    NSLog(@"TutkClient: receive nalu %d", nalu_type);
                }
                
                if (frameStartIdex < 0) {
                    frameStartIdex = i;
                    i = i + 4;
                    continue;
                }
                
                frameEndIndex = i;
     
                // Found one frame
                if (frameStartIdex >=0 && frameEndIndex >= 0) {
                    
                    int fsize = frameEndIndex - frameStartIdex;
                    [self processVideoFrame:(char*)(frameBuffer + frameStartIdex) frameSize:fsize];
                    
                    frameStartIdex = frameEndIndex;
                    frameEndIndex = -1;
                }
                
            }
        }
        
        // reset the frame buffer to receive new data
        if (frameStartIdex >= 0) {
            memcpy(frameBuffer, (char*)(frameBuffer + frameStartIdex) , frameBufferIndex - frameStartIdex);
            frameBufferIndex = frameBufferIndex - frameStartIdex;
        }
    }
    free(buf);
    free(frameBuffer);
    NSLog(@"[thread_ReceiveVideo] thread exit");
    return;
}

- (void) processVideoFrame: (char*) frame frameSize: (int) frameSize {
    [self.delegate tutkClient:self didReceiveVideoFrame:frame frameSize:frameSize frameNumber:self.frameNo uid:self.uid deviceSN:self.deviceSN];
    self.frameNo = self.frameNo + 1;
}

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

-(void) startLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN {
    [self initialize:uid];
    [self login];
    [self requestLiveVideo: deviceSN];
}

-(void)stopLiveVideo:(NSString *)uid deviceSN:(NSString *)deviceSN {
    [self.videoThread cancel];
    avClientStop(self.currentAvIndex);
    NSLog(@"avClientStop OK");
    IOTC_Session_Close(self.sid);
    NSLog(@"IOTC_Session_Close OK");
    avDeInitialize();
    IOTC_DeInitialize();
    NSLog(@"StreamClient exit.");
}

@end
