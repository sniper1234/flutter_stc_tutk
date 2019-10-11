//
//  TutkClientManager.m
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 24/08/19.
//

#import "TutkClientManager.h"
#import "TutkTunnelClient.h"
#import "TutkCommandManager.h"

@interface TutkClientManager()<TutkCommandManagerDelegate>
@property (nonatomic) TutkTunnelClient* tutkTunnelClient;
@property (nonatomic) TutkCommandManager* tutkCommandManager;
@end

@implementation TutkClientManager

-(instancetype)init {
    self = [super init];
    return self;
}

- (void) startLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN {
    
    NSLog(@"TutkClientManager.startLiveVideo uid=%@, deviceSN=%@", uid, deviceSN);
    
    if (self.tutkTunnelClient == nil) {
        self.tutkTunnelClient = [[TutkTunnelClient alloc] init];
    }
    
    if (self.tutkCommandManager == nil) {
        self.tutkCommandManager = [[TutkCommandManager alloc] init];
        self.tutkCommandManager.delegate = self;
    }
    
    [self.tutkCommandManager stop];
    [self.tutkTunnelClient disconnect];
    
    [self.tutkTunnelClient connect:uid completion:^(BOOL isConnected, NSString* ip, int port) {
        if (isConnected) {
            [self.tutkCommandManager start: deviceSN withUid:uid];
        }
    }];
}

- (void) stopLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN {
    [self.tutkCommandManager stop];
    [self.tutkTunnelClient disconnect];
}


- (void)tutkCommandManager:(TutkCommandManager*)manager didReceiveVideoFrame:(char*) frameBuffer frameSize:(int) frameSize frameNumber:(int) frameNumber uid: (NSString*) uid deviceSN:(NSString*) deviceSN {
    
    [self.delegate tutkClientManager:self didReceiveVideoFrame:frameBuffer frameSize:frameSize frameNumber:frameNumber uid:uid deviceSN:deviceSN];
}

@end
