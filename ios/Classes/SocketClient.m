//
//  SocketClient.m
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 22/08/19.
//

#import "SocketClient.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

@interface SocketClient() {
    CFSocketRef _socketRef;
}

@end

char* LOCAL_IP_ADDR = "127.0.0.1";
int LOCAL_IP_PROT = 20000;
CFReadStreamRef readStreamRef;
CFWriteStreamRef writeStreamRef;

@implementation SocketClient

- (void)connectAddress:(NSString*) address port:(int)port {
    
    NSLog(@"SocketClient.connectAddress %@:%d", address, port);
    if (!_socketRef) {
        
        // 创建socket关联的上下文信息
        
        /*
         typedef struct {
         CFIndex    version; 版本号, 必须为0
         void *    info; 一个指向任意程序定义数据的指针，可以在CFSocket对象刚创建的时候与之关联，被传递给所有在上下文中回调
         const void *(*retain)(const void *info); info 指针中的retain回调，可以为NULL
         void    (*release)(const void *info); info指针中的release回调，可以为NULL
         CFStringRef    (*copyDescription)(const void *info); 回调描述，可以n为NULL
         } CFSocketContext;
         
         */
        
        CFSocketContext sockContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
        
        //创建一个socket
        _socketRef = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketConnectCallBack, ServerConnectCallBack, &sockContext);
        
        //创建sockadd_in的结构体，改结构体作为socket的地址，IPV6需要改参数
        
        //sockaddr_in
        // sin_len;  长度
        //sin_family;协议簇， 用AF_INET -> 互联网络， TCP，UDP 等等
        //sin_port; 端口号（使用网络字节顺序）htons:将主机的无符号短整形数转成网络字节顺序
        //in_addr sin_addr; 存储IP地址， inet_addr()的功能是将一个点分十进制的IP转换成一个长整型数(u_long类型)，若字符串有效则将字符串转换为32位二进制网络字节序的IPV4地址， 否则为IMADDR_NONE
        //sin_zero[8]; 让sockaddr与sockaddr_in 两个数据结构保持大小相同而保留的空字节，无需处理
        
        struct sockaddr_in Socketaddr;
        //memset： 将addr中所有字节用0替代并返回addr，作用是一段内存块中填充某个给定的值，它是对较大的结构体或数组进行清零操作的一种最快方法
        memset(&Socketaddr, 0, sizeof(Socketaddr));
        Socketaddr.sin_len = sizeof(Socketaddr);
        Socketaddr.sin_family = AF_INET;
        Socketaddr.sin_port = htons(port);
        Socketaddr.sin_addr.s_addr = inet_addr([address UTF8String]);
        
        //将地址转化为CFDataRef
        CFDataRef dataRef = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&Socketaddr, sizeof(Socketaddr));
        
        NSLog(@"SocketClient.connectAddress CFSocketConnectToAddress.connect");
        //连接
        //CFSocketError    CFSocketConnectToAddress(CFSocketRef s, CFDataRef address, CFTimeInterval timeout);
        //第一个参数  连接的socket
        //第二个参数  连接的socket的包含的地址参数
        //第三个参数 连接超时时间，如果为负，则不尝试连接，而是把连接放在后台进行，如果_socket消息类型为kCFSocketConnectCallBack，将会在连接成功或失败的时候在后台触发回调函数
        CFSocketError error = CFSocketConnectToAddress(_socketRef, dataRef, -1);
        
        NSLog(@"SocketClient.connectAddress CFSocketConnectToAddress.error = %ld", (long)error);
        //加入循环中
        //获取当前线程的runLoop
        CFRunLoopRef runloopRef = CFRunLoopGetCurrent();
        //把socket包装成CFRunLoopSource, 最后一个参数是指有多个runloopsource通过一个runloop时候顺序，如果只有一个source 通常为0
        CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socketRef, 0);
        
        //加入运行循环
        //第一个参数：运行循环管
        //第二个参数： 增加的运行循环源, 它会被retain一次
        //第三个参数：用什么模式把source加入到run loop里面,使用kCFRunLoopCommonModes可以监视所有通常模式添加source
        CFRunLoopAddSource(runloopRef, sourceRef, kCFRunLoopCommonModes);
        
        //之前被retain一次，这边要释放掉
        CFRelease(sourceRef);
        
    }
    
}

-(void) disconnect {
    [self _releseSocket];
}

- (long)sendData:(char *)dataToSend length:(long) length {
    
    NSLog(@"SocketClient.sendData sending data %ld bytes", length);
    
    if (!_socketRef) {
        NSLog(@"SocketClient.sendData error=socket not connect");
        return 0;
    }
    
    /** 成功则返回实际传送出去的字符数, 失败返回-1. 错误原因存于errno*/
    long sendData = send(CFSocketGetNative(_socketRef), dataToSend, length, 0);
    
    if (sendData < 0) {
        
    }
    
    NSLog(@"SocketClient.sendData sended result=%ld", sendData);
    return sendData;
}

- (long) readData:(char*) buffer maxLength:(int)maxLength
{
    //定义一个字符型变量
    //char buffer[512];
    
    /*
     int recv(SOCKET s, char FAR *buf, int len, int flags);
     
     不论是客户还是服务器应用程序都用recv函数从TCP连接的另一端接收数据
     1. 第一个参数指定接收端套接字描述符
     2.第二个参数指明一个缓冲区，改缓冲区用来存放recv函数接受到的数据
     3. 第三个参数指明buf的长度
     4.第四个参数一般置0
     
     */
    
    //若无错误发生，recv() 返回读入的字节数。如果连接已终止，返回0 如果发生错误，返回-1， 应用程序可通过perror() 获取相应错误信息
    long readDataLength = recv(CFSocketGetNative(_socketRef), buffer, maxLength, 0);
    NSLog(@"SocketClient.readData length = %ld", readDataLength);
    return readDataLength;
}

/**
 回调函数
 
 @param s socket对象
 @param callbackType 这个socket对象的活动类型
 @param address socket对象连接的远程地址，CFData对象对应的是socket对象中的protocol family (struct sockaddr_in 或者 struct sockaddr_in6), 除了type 类型 为kCFsocketAcceptCallBack 和kCFSocketDataCallBack ，否则这个值通常是NULL
 @param data 跟回调类型相关的数据指针
 kCFSocketConnectCallBack : 如果失败了， 它指向的就是SINT32的错误代码
 kCFSocketAcceptCallBack : 它指向的就是CFSocketNativeHandle
 kCFSocketDataCallBack : 它指向的就是将要进来的Data
 其他情况就是NULL
 
 @param info 与socket相关的自定义的任意数据
 
 */
void ServerConnectCallBack(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    SocketClient* socketClient = (__bridge SocketClient*)info;
    if (data != nil) {
        NSLog(@"SocketClient.ServerConnectCallBack connect failed");
        // close socket
        [socketClient disconnect];
    } else {
        NSLog(@"SocketClient.ServerConnectCallBack connect success");
    }
    
    [socketClient.delegate socketClient:socketClient updateConnectStatus:data == nil];
    
//    ViewController *vc = (__bridge ViewController *)(info);
//    //判断是不是NULL
//    if (data != NULL)
//    {
//        printf("----->>>>>>连接失败\n");
//
//        [vc performSelector:@selector(_releseSocket) withObject:nil];
//
//    }
//    else
//    {
//        printf("----->>>>>>连接成功\n");
//        [vc performSelectorInBackground:@selector(_readStreamData) withObject:nil];
//
//    }
    
}

- (void)_releseSocket
{
    if (_socketRef) {
        CFRelease(_socketRef);
    }
    
    _socketRef = NULL;
    
   // self.infoLabel.text = @"----->>>>>>连接失败-----";
    
    
}

//- (void)_initSocket
//{
//    @autoreleasepool {
//        //创建Socket， 指定TCPServerAcceptCallBack
//        //作为kCFSocketAcceptCallBack 事件的监听函数
//        //参数1： 指定协议族，如果参数为0或者负数，则默认为PF_INET
//        //参数2：指定Socket类型，如果协议族为PF_INET，且该参数为0或者负数，则它会默认为SOCK_STREAM,如果要使用UDP协议，则该参数指定为SOCK_DGRAM
//        //参数3：指定通讯协议。如果前一个参数为SOCK_STREAM,则默认为使用TCP协议，如果前一个参数为SOCK_DGRAM,则默认使用UDP协议
//        //参数4：指定下一个函数所监听的事件类型
//        CFSocketRef _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, TCPServerAcceptCallBack, NULL);
//
//        if (_socket == NULL) {
//            NSLog(@"————————创建socket 失败");
//            return;
//        }
//
//        BOOL reused = YES;
//
//        //设置允许重用本地地址和端口
//        setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (const void *)&reused, sizeof(reused));
//
//        //定义sockaddr_in类型的变量， 该变量将作为CFSocket的地址
//        struct sockaddr_in Socketaddr;
//        memset(&Socketaddr, 0, sizeof(Socketaddr));
//        Socketaddr.sin_len = sizeof(Socketaddr);
//        Socketaddr.sin_family = AF_INET;
//
//        //设置服务器监听地址
//        Socketaddr.sin_addr.s_addr = inet_addr(TEST_IP_ADDR);
//        //设置服务器监听端口
//        Socketaddr.sin_port = htons(TEST_IP_PROT);
//
//        //将ipv4 的地址转换为CFDataRef
//        CFDataRef address = CFDataCreate(kCFAllocatorDefault,  (UInt8 *)&Socketaddr, sizeof(Socketaddr));
//
//        //将CFSocket 绑定到指定IP地址
//        if (CFSocketSetAddress(_socket, address) != kCFSocketSuccess) {
//
//            //如果_socket 不为NULL， 则f释放_socket
//            if (_socket) {
//                CFRelease(_socket);
//                exit(1);
//            }
//
//            _socket = NULL;
//        }
//
//        //启动h循环箭筒客户链接
//        NSLog(@"----启动循环监听客户端连接---");
//        //获取当前线程的CFRunloop
//        CFRunLoopRef cfrunLoop = CFRunLoopGetCurrent();
//        //将_socket包装成CFRunLoopSource
//        CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
//        //为CFRunLoop对象添加source
//        CFRunLoopAddSource(cfrunLoop, source, kCFRunLoopCommonModes);
//        CFRelease(source);
//        //运行当前线程的CFrunLoop
//        CFRunLoopRun();
//    }
//}

//void readStream(CFReadStreamRef readStream, CFStreamEventType eventype, void*  clientCallBackInfo) {
//
//    UInt8 buff[2048];
//
//    NSString *aaa = (__bridge NSString *)(clientCallBackInfo);
//    NSLog(@"+++++++>>>>>%@", aaa);
//
//    //--从可读的数据流中读取数据，返回值是多少字节读到的， 如果为0 就是已经全部结束完毕，如果是-1 则是数据流没有打开或者其他错误发生
//    CFIndex hasRead = CFReadStreamRead(readStream, buff, sizeof(buff));
//
//    if (hasRead > 0) {
//
//        NSLog(@"----->>>>>接受到数据:%s \n", buff);
//        const char *str = "test,  test , test \n";
//
//        //向客户端输出数据
//        CFWriteStreamWrite(writeStreamRef, (UInt8 *)str, strlen(str) + 1);
//    }
//
//}

//void TCPServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
//{
//    //如果有客户端Socket连接进来
//    if (kCFSocketAcceptCallBack == type) {
//
//        //获取本地Socket的Handle， 这个回调事件的类型是kCFSocketAcceptCallBack，这个data就是一个CFSocketNativeHandle类型指针
//        CFSocketNativeHandle  nativeSocketHandle = *(CFSocketNativeHandle *)data;
//
//        //定义一个255数组接收这个新的data转成的socket的地址，SOCK_MAXADDRLEN表示最长的可能的地址
//        uint8_t name[SOCK_MAXADDRLEN];
//        //这个地址数组的长度
//        socklen_t namelen = sizeof(name);
//
//        /*
//
//         */
//
//        //MARK:获取socket信息
//        //第一个参数 已经连接的socket
//        //第二个参数 用来接受地址信息
//        //第三个参数 地址长度
//        //getpeername 从已经连接的socket中获的地址信息， 存到参数2中，地址长度放到参数3中，成功返回0， 如果失败了则返回别的数字，对应不同错误码
//
//        if (getpeername(nativeSocketHandle, (struct sockaddr *)name, &namelen) != 0) {
//
//            perror("++++++++getpeername+++++++");
//
//            exit(1);
//        }
//
//        //获取连接信息
//        struct sockaddr_in *addr_in = (struct sockaddr_in *)name;
//
//        // inet_ntoa 将网络地址转换成"." 点隔的字符串格式
//        NSLog(@"-------->>>>%s===%d--连接进来了", inet_ntoa(addr_in-> sin_addr), addr_in->sin_port);
//
//        //创建一组可读/可写的CFStream
//        readStreamRef = NULL;
//        writeStreamRef = NULL;
//
//        //创建一个和Socket对象相关联的读取数据流
//        //参数1 ：内存分配器
//        //参数2 ：准备使用输入输出流的socket
//        //参数3 ：输入流
//        //参数4 ：输出流
//        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStreamRef, &writeStreamRef);
//
//        //CFStreamCreatePairWithSocket() 操作成功后，readStreamRef和writeStream都指向有效的地址，因此判断是不是还是之前设置的NULL就可以了
//        if (readStreamRef && writeStreamRef) {
//            //打开输入流 和输出流
//            CFReadStreamOpen(readStreamRef);
//            CFWriteStreamRef(writeStreamRef) = NULL;
//
//            //一个结构体包含程序定义数据和回调用来配置客户端数据流行为
//            NSString *aaa = @" 这 是 一个 测 测试 的 代码";
//
//            CFStreamClientContext context = {0, (__bridge void *)(aaa), NULL, NULL };
//
//            //指定客户端的数据流， 当特定事件发生的时候， 接受回调
//            //参数1 : 需要指定的数据流
//            //参数2 : 具体的事件，如果为NULL，当前客户端数据流就会被移除
//            //参数3 : 事件发生回调函数，如果为NULL，同上
//            //参数4 : 一个为客户端数据流保存上下文信息的结构体，为NULL同上
//            //CFReadStreamSetClient  返回值为true 就是数据流支持异步通知， false就是不支持
//            if (CFReadStreamSetClient(readStreamRef, kCFStreamEventHasBytesAvailable, readStream, &context)) {
//
//                exit(1);
//
//            }
//
//            //将数据流加入循环
//            CFReadStreamScheduleWithRunLoop(readStreamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
//            const char *str = "+++welcome++++\n";
//
//            //向客户端输出数据
//            CFWriteStreamWrite(writeStreamRef, (UInt8 *)str, strlen(str) + 1);
//        }
//        else
//        {
//            //如果失败就销毁已经连接的socket
//            close(nativeSocketHandle);
//        }
//    }
//
//}

@end
