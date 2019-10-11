//
//  TutkCommandManager.m
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 24/08/19.
//

#import "TutkCommandManager.h"
#import "SocketClient.h"
#import "TutkLoctlCommand.h"

#define MAX_SOCKET_DATA_BUFFER 20000
#define MAX_COMMAND_SIZE 5000
#define VIDEO_BUF_SIZE    2000000
#define MAX_BUF_SIZE 102400
#define FRAME_BUF_SIZE    5000000


@interface TutkCommandManager()

@property (nonatomic) NSThread* receiveThread;
@property (nonatomic) NSThread* sendThread;
@property (nonatomic) NSMutableArray* sendCommandQueue;
@property (nonatomic) NSMutableArray* receiveCommandQueue;
@property (nonatomic) SocketClient* socketClient;

@property (nonatomic, copy) NSString* currentDeviceSN;
@property (nonatomic, copy) NSString* currentUid;

@property(nonatomic) uint frameNo;

@property(nonatomic) char* frameBuffer;
@property(nonatomic) int frameBufferIndex;

@end

@implementation TutkCommandManager

- (instancetype)init {
    self = [super init];
    return self;
}

-(void) start:(NSString*) deviceSN withUid:(nonnull NSString *)uid {
    NSLog(@"TutkCommandManager.start");
    
    self.socketClient = [[SocketClient alloc] init];
    self.socketClient.delegate = self;
    [self.socketClient connectAddress:@"127.0.0.1" port:20000];
    
    self.currentDeviceSN = deviceSN;
    self.currentUid = uid;
}

-(void) stop {
    [self.receiveThread cancel];
    [self.socketClient disconnect];

    self.currentDeviceSN = nil;
}

-(void) login {
    
    NSLog(@"TutkCommandManager.login");
    
    struct TutkLoctlCommand loginCommand;
    struct TutkLoctlCommandDataLogin loginCommandData;
    int dataLength = sizeof(loginCommand) - MAX_DATA_SIZE + sizeof(loginCommandData);
    
    loginCommand.command =  TUTK_IOCTL_CLIENT_LOGIN;
    loginCommand.length = dataLength;
    loginCommandData.tutk_ioctl_version = 1;
    loginCommandData.media_chanel = 0;
    
    strcpy((char*)loginCommandData.client_name,"admin");
    strcpy((char*)loginCommandData.password, "888888");
    
    memcpy(loginCommand.data, &loginCommandData, sizeof(loginCommandData));

    [self sendCommand:(char*)&loginCommand length:dataLength];
}


- (void) requestLiveVideo {
    
    if (self.currentDeviceSN == nil) {
        NSLog(@"TutkCommandManager.requestLiveVideo error, deviceSN should not be nil");
        return;
    }

    struct TutkLoctlCommand videoPlayCommand;
    struct TutkLoctlCommandDataVideoPlay videoPlayCommandData;
    int dataLength = sizeof(videoPlayCommand) - MAX_DATA_SIZE + sizeof(videoPlayCommandData);
    
    videoPlayCommand.command = TUTK_IOCTL_ENTER_STREAM_MODE;
    videoPlayCommand.length = dataLength;
    
    strcpy(videoPlayCommandData.target_device_sn, [self.currentDeviceSN UTF8String]);
    
    memcpy(videoPlayCommand.data, &videoPlayCommandData, sizeof(videoPlayCommandData));
    
    [self sendCommand:(char*)&videoPlayCommand length:dataLength];
}


-(void)sendCommand:(char*)commandDataBuffer length:(int)commandDataLength {
    char sendBuf[MAX_COMMAND_SIZE + 8];
    strcpy((char*)sendBuf, "head");
    memcpy(sendBuf + 4, commandDataBuffer, commandDataLength);
    strcpy((char*)sendBuf + 4 + commandDataLength,"tail");
    
    // update data length, add 8 bytes for head and tail
    int32_t realCommandLength = 0;
    memcpy(&realCommandLength, commandDataBuffer, 4);
    realCommandLength = realCommandLength + 8;
    memcpy(sendBuf + 4, &realCommandLength, 4);
    [self.socketClient sendData:sendBuf length:realCommandLength];
    
//    NSData* data = [NSData dataWithBytes:sendBuf length:realCommandLength];
//    NSString* filePath = [NSString stringWithFormat:@"%@-login-%lld", [[NSBundle mainBundle] bundlePath], (int64_t)[NSDate date].timeIntervalSince1970];
//    NSLog(@"TutkCommandManager.sendCommand write to file: %@", filePath);
//    [data writeToFile:filePath atomically:YES];
}

-(void) logout {
    
}

- (void)startCommandThread {
    
    NSLog(@"TutkCommandManager.startCommandThread");
    
    // 创建线程
    self.receiveThread = [[NSThread alloc] initWithTarget:self selector:@selector(commandReceiveThreadProcess) object:nil];
    // 设置线程名
    [self.receiveThread setName:@"commandReceiveThread"];
    // 设置优先级 优先级从0到1 1最高
    [self.receiveThread setThreadPriority:0.9];
    // 启动线程
    [self.receiveThread start];
}

-(void) commandReceiveThreadProcess {
    
    long commandBufferActualLength = 0;
    char* commandBuffer = malloc(FRAME_BUF_SIZE);
    char* socketDataBuffer = malloc(MAX_SOCKET_DATA_BUFFER);
    // initial buffer for video frames
    self.frameBuffer = malloc(FRAME_BUF_SIZE);
    self.frameBufferIndex = 0;
    
    while (![self.receiveThread isCancelled]) {
        long actualLength = [self.socketClient readData:socketDataBuffer maxLength:MAX_SOCKET_DATA_BUFFER];
        
        // Insert socket data into buffer
        if (actualLength > 0) {
            memcpy(commandBuffer + commandBufferActualLength, socketDataBuffer, actualLength);
            commandBufferActualLength = actualLength + commandBufferActualLength;
        }

        int firstFrameStartIndex = -1;
        int lastFrameEndIndex = -1;
        
        // extract frame from the buffer
        for(int i = 0; i < commandBufferActualLength; i++) {
            if (commandBuffer[i] == 'h'
                && commandBuffer[i+1] == 'e'
                && commandBuffer[i+2] == 'a'
                && commandBuffer[i+3] == 'd') {
                
                if (firstFrameStartIndex < 0) {
                    firstFrameStartIndex = i;
                }
                
                
                for(int j = i+4; j < commandBufferActualLength; j++) {
                    if (commandBuffer[j] == 't'
                && commandBuffer[j+1] == 'a'
                && commandBuffer[j+2] == 'i'
                && commandBuffer[j+3] == 'l') {
                        
                        long frameLength = j - i - 4;
                        
//                     static int count = 0;
//                        NSData* data = [NSData dataWithBytes:commandBuffer + i + 4 length:frameLength];
//                        NSString* filePath = [NSString stringWithFormat:@"%@-commanddata-%d", [[NSBundle mainBundle] bundlePath], count];
//                        NSLog(@"TutkCommandManager.sendCommand write to file: %@", filePath);
//                        [data writeToFile:filePath atomically:YES];
//                        count = count + 1;
//
//                        NSLog(@"TutkCommandManager.commandReceiveThreadProcess: Found a frame: length = %ld", frameLength);
                        [self handleReceivedCommand:commandBuffer + i + 4 length:frameLength];

                        i = j + 4;
                        
                        lastFrameEndIndex = j + 4;
                    }
                }
            }
        }
        
        if (lastFrameEndIndex > 0 && commandBufferActualLength > lastFrameEndIndex) {
            memcpy(commandBuffer + firstFrameStartIndex, commandBuffer + lastFrameEndIndex, commandBufferActualLength - lastFrameEndIndex);
            commandBufferActualLength = commandBufferActualLength - lastFrameEndIndex + firstFrameStartIndex;
        }
        
        
        usleep(30000);
    }

    free(socketDataBuffer);
    free(commandBuffer);
    
    // free buffer for video frames
    free(self.frameBuffer);
    self.frameBuffer = nil;
}

-(void) handleReceivedCommand:(char*) commandData length:(long) dataLength {
    
    if (dataLength < 8) {
        NSLog(@"handleReceivedCommand wrong dataLength");
        return;
    }
    
    struct TutkLoctlCommand command;
    memcpy(&command, commandData, 8);
    
    if (command.command == TUTK_IOCTL_CLIENT_LOGIN_RESP) {
        // login Response
        struct TutkLoctlCommandDataLoginResponse loginResponse;
        memcpy(&loginResponse, commandData + 8, 1);
        
        if (loginResponse.result == 0) {
            // login success
            // start video
            [self requestLiveVideo];
        } else if (loginResponse.result == 1) {
            // unknwon error
        } else if (loginResponse.result == 2) {
            // invalid user or password
        }
    } else if (command.command == TUTK_IOCTL_CLIENT_LOGIN_RESP) {
        
    } else if (command.command == TUTK_IOCTL_MEDIA_CONTENT) {
        
        int videoDataLength = command.length - 8 - 8;
        //memcpy(command.data, commandData + 8, videoDataLength);
        NSLog(@"TutkCommandManager.handleReceivedCommand: receive video data, length = %d", videoDataLength);
        [self handleReceivedVideoData:commandData + 8 length:videoDataLength];
        
    }
}

- (void) handleReceivedVideoData:(char*) videoData length:(long) videoDataLength {
//    static int count = 0;
//    NSData* data = [NSData dataWithBytes:videoData length:dataLength];
//    NSString* filePath = [NSString stringWithFormat:@"%@-video-%d", [[NSBundle mainBundle] bundlePath], count];
//    NSLog(@"TutkCommandManager.sendCommand write to file: %@", filePath);
//    [data writeToFile:filePath atomically:YES];
//    count = count + 1;
    
    // Put data into frame buffer
    memcpy((char*)(self.frameBuffer + self.frameBufferIndex), videoData, videoDataLength);
    self.frameBufferIndex += (int)videoDataLength;
    
   // Extract frame from frame buffer
   int frameStartIdex = -1;
   int frameEndIndex = -1;
   for (int i = 0; i < self.frameBufferIndex; i++) {
       if ((int8_t)self.frameBuffer[i] == 0x00 && (int8_t)self.frameBuffer[i+1] == 0x00 && (int8_t)self.frameBuffer[i+2] == 0x00 && (int8_t)self.frameBuffer[i+3] == 0x01) {
           
           int nalu_type = (self.frameBuffer[4] & 0x1F);
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
           if (frameStartIdex >= 0 && frameEndIndex >= 0) {
               
               int fsize = frameEndIndex - frameStartIdex;
//               [self processVideoFrame:(char*)(videoData + frameStartIdex) frameSize:fsize];
               
//               NSData* data = [NSData dataWithBytes:(char*)(self.frameBuffer + frameStartIdex) length:fsize];
//               NSString* filePath = [NSString stringWithFormat:@"%@-frame-%d", [[NSBundle mainBundle] bundlePath], self.frameNo];
//               NSLog(@"TutkCommandManager.handleReceivedVideoData write to file: %@", filePath);
//               [data writeToFile:filePath atomically:YES];

               [self.delegate tutkCommandManager:self didReceiveVideoFrame:(char*)(self.frameBuffer + frameStartIdex) frameSize:fsize frameNumber:self.frameNo uid:self.currentUid deviceSN:self.currentDeviceSN];
               
               self.frameNo = self.frameNo + 1;
               
               frameStartIdex = frameEndIndex;
               frameEndIndex = -1;
           }
       }
   }
    
    // reset the frame buffer to receive new data
    if (frameStartIdex > 0) {
        memcpy(self.frameBuffer, (char*)(self.frameBuffer + frameStartIdex) , self.frameBufferIndex - frameStartIdex);
        self.frameBufferIndex = self.frameBufferIndex - frameStartIdex;
    }
}

-(void) commandSendThreadProcess {
    while (![self.sendThread isCancelled]) {
        
    }
}

- (void) socketClient:(SocketClient*) client updateConnectStatus:(BOOL) isConnect {
    
    NSLog(@"TutkCommandManager.socketClientUpdateConnectStatus: isConnect = %d", isConnect);
    
    if (isConnect) {
        
        // start receiving data thread
        [self startCommandThread];
        
        // login command
        [self login];
        
        // start video
        [self requestLiveVideo];
    }
}

@end
