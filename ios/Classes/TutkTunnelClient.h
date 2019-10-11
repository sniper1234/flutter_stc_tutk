//
//  TutkTunnelClient.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 22/08/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define MAX_SERVER_CONNECT_NUM        4
#define SSH_MAPPING_LOCAL_PORT        20000
#define SSH_MAPPING_REMOTE_PORT        22

// Declare the block variable
typedef void (^TunnelConnectStatusCompletion)(BOOL isConnected, NSString* ip, int port);

@interface TutkTunnelClient : NSObject

-(BOOL) connect:(NSString*)uid completion: (TunnelConnectStatusCompletion) completion;

-(BOOL) disconnect;

@end

NS_ASSUME_NONNULL_END
