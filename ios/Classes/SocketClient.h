//
//  SocketClient.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 22/08/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SocketClient;

@protocol SocketClientDelegate <NSObject>

- (void) socketClient:(SocketClient*) client updateConnectStatus:(BOOL) isConnect;

@end

@interface SocketClient : NSObject

@property (nonatomic, weak) id<SocketClientDelegate> delegate;

- (void)connectAddress:(NSString*) address port:(int)port;
- (long)sendData:(char *)dataToSend length:(long) length;
- (long)readData:(char*) buffer maxLength:(int) maxLength;
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
