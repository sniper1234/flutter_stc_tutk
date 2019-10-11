//
//  TutkTunnelClient.m
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 22/08/19.
//

#import "TutkTunnelClient.h"
#import "P2PTunnelAPIs.h"
#import "AVAPIs.h"
#import "IOTCAPIs.h"
#import "RDTAPIs.h"


@interface TutkTunnelClient() {
    
}

@property (nonatomic) NSString* uid;
@property (nonatomic) int sessionId;
@property (nonatomic) int sshIndex;
@property (nonatomic) TunnelConnectStatusCompletion completionHandler;
@end

@implementation TutkTunnelClient

typedef struct st_AuthData
{
    char szUsername[64];
    char szPassword[64];
} sAuthData;


- (instancetype)init {
    self = [super init];
    self.sessionId = -1;
    self.sshIndex = -1;
    return self;
}

// Create and assign the block
//distanceFromRateAndTime = ^double(double rate, double time) {
//    return rate * time;
//};

-(BOOL) disconnect {
    
    self.completionHandler = nil;
    
    if (self.sessionId < 0) {
        // already disconnected
        return TRUE;
    }
    
    int ret = TUNNEL_ER_NoERROR;
    P2PTunnelAgent_StopPortMapping(self.sshIndex);
    ret = P2PTunnelAgent_Disconnect(self.sessionId);
    
    if (ret != TUNNEL_ER_NoERROR) {
        NSLog(@"TutkTunelClient.disconnect P2PTunnelAgent_Disconnect Error");
    }
    ret = P2PTunnelAgentDeInitialize();
    
    self.sessionId = -1;
    
    NSLog(@"TutkTunelClient.disconnect: ret=%d", ret);
    return ret == TUNNEL_ER_NoERROR;
}

-(BOOL) connect:(NSString*)uid completion: (TunnelConnectStatusCompletion) completion
{
    [self disconnect];
    
    self.completionHandler = completion;

    sAuthData authData;
    strcpy(authData.szUsername, "Tutk.com");
    strcpy(authData.szPassword, "P2P Platform");
    
    // initialize
    int ret = P2PTunnelAgentInitialize(MAX_SERVER_CONNECT_NUM);
    if (ret < 0)
    {
        NSLog(@"P2PTunnelAgentInitialize error[%d]!\n", ret);
        return FALSE;
    }
    
    // Set callback
    P2PTunnelAgent_GetStatus(TunnelStatusCB, (__bridge void *)self);
    
    int nErrFromDevice = 0;
    /* If you don't want to use authentication mechanism, you can give NULL argument
     gSID[i] = P2PTunnelAgent_Connect(gUID, NULL, 0, &nErrFromDevice);
     */
    self.sessionId = P2PTunnelAgent_Connect([uid UTF8String], (void *)&authData, sizeof(sAuthData), &nErrFromDevice);
    
    if (self.sessionId < 0) {
        printf("P2PTunnelAgent_Connect failed[%d], device respond reject reason[%d]\n", self.sessionId, nErrFromDevice);
        return FALSE;
    }
    else {
        printf("P2PTunnelAgent_Connect OK\n");
    }
    
    self.sshIndex = P2PTunnelAgent_PortMapping(self.sessionId, SSH_MAPPING_LOCAL_PORT, SSH_MAPPING_REMOTE_PORT);
    if (self.sshIndex < 0)
    {
        printf("P2PTunnelAgent_PortMapping SSH error[%d]!\n", self.sshIndex);
    } else {
        printf("P2PTunnelAgent_PortMapping OK\n");
    }
    
    self.completionHandler(TRUE, @"127.0.0.1", SSH_MAPPING_LOCAL_PORT);
    return TRUE;
}

void __stdcall TunnelStatusCB(int nErrorCode, int nSID, void *pArg)
{
    printf("P2PTunnelAgent.TunnelStatusCB: nErrorCode=%d, SID=%d\n", nErrorCode, nSID);
    TutkTunnelClient* client = (__bridge TutkTunnelClient*)pArg;
    if (nErrorCode == TUNNEL_ER_DISCONNECTED)
    {
        [client disconnect];
        client.completionHandler(FALSE, @"", 0);
    } else {
        
        client.completionHandler(TRUE, @"127.0.0.1", SSH_MAPPING_LOCAL_PORT);
    }
}

//int main(int argc, char *argv[])
//{
//    if (argc < 2)
//    {
//        printf("No UID input!!!\n");
//        return 0;
//    }
//
//    char *s = "My arg Pass to call back function";
//    P2PTunnelAgent_GetStatus(TunnelStatusCB, (void *)s);
//
//    sAuthData authData;
//    strcpy(authData.szUsername, "Tutk.com");
//    strcpy(authData.szPassword, "P2P Platform");
//    if (TunnelAgentStart(&authData) < 0) //Ó³Éä±¾µØ¶Ë¿Úµ½Ô¶¶ËµÄ22¶Ë¿Ú
//    {
//        printf("TunnelAgentStart failed\n");
//        return -1;
//    }
//
//    SOCKET sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
//    if (sock == INVALID_SOCKET)
//    {
//        exit(-1);
//    }
//    int nRecvBuf = 64 * 1024;
//    setsockopt(sock,SOL_SOCKET,SO_RCVBUF,(const char*)&nRecvBuf,sizeof(int));
//
//    SOCKADDR_IN addr_Server; //·þÎñÆ÷µÄµØÖ·µÈÐÅÏ¢
//    addr_Server.sin_family = AF_INET;
//    addr_Server.sin_port = htons(20000); //±¾µØ³ÌÐòÁ¬½Óµ½±¾µØ¶Ë¿Ú
//    addr_Server.sin_addr.S_un.S_addr = inet_addr("127.0.0.1");
//    if (connect(sock, (SOCKADDR*)&addr_Server, sizeof(addr_Server)) == SOCKET_ERROR)
//    {
//        //·þÎñÆ÷Óë±¾µØµØÖ·°ó¶¨
//        exit(-1);
//    }
//    Utils::AutoReleaser<SOCKET> sock_closer(sock,(void(*)(SOCKET))closesocket);
//
//    SDL_Init(SDL_INIT_VIDEO);
//
//    Scene::TUTK_IOCTL_Transceiver transceiver(sock);//½ÓÏÂÀ´µÄÍ¨ÐÅ¿ÉÒÔÖ±½ÓÊ¹ÓÃÁ¬½Óµ½±¾µØ¶Ë¿ÚµÄsocket
//
//    Login login;
//    login.tutk_ioctl_version = TUTK_IOCTL_VERSION;
//    strcpy((char*)login.client_name,"admin");
//    strcpy((char*)login.password, "888888");
//    login.media_chanel = 0;
//
//    TUTK_IOCTL login_req(TUTK_IOCTL_CLIENT_LOGIN,0,login);
//
//    if(!transceiver.SendCommand(&login_req)) //ÃüÁîºÍÃ½ÌåÊý¾Ý¶¼×ßÕâ¸ösocket
//    {
//        printf("send cmd failed!\n");
//        return -1;
//    }
//
//    std::string mode;
//    while (1) {
//        while (transceiver.ReceiveCommand(1000) > 0);
//        std::cout << "choose to enter \"record\" or \"live\" mode:(\"exit\" to exit)" << std::endl;
//        std::cin >> mode;
//        if ("record" == mode) {
//            RecordPlay(transceiver);
//        }
//        else if ("live" == mode) {
//            LivePlay(transceiver);
//        }
//        else if ("exit" == mode) {
//            break;
//        }
//    }
//
//    media_stop = true;
//    program_exit = true;
//    Sleep(1200);
//    printf("IOTC_Session_Close OK\n");
//
//    printf("StreamClient exit...\n");
//    return 0;
//}

@end
