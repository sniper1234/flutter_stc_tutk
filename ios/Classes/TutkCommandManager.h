//
//  TutkCommandManager.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 24/08/19.
//

#import <Foundation/Foundation.h>
#import "SocketClient.h"

NS_ASSUME_NONNULL_BEGIN

@class TutkCommandManager;

@protocol TutkCommandManagerDelegate <NSObject>

- (void)tutkCommandManager:(TutkCommandManager*)manager didReceiveVideoFrame:(char*) frameBuffer frameSize:(int) frameSize frameNumber:(int) frameNumber uid: (NSString*) uid deviceSN:(NSString*) deviceSN;

// ... other methods here
@end


@interface TutkCommandManager : NSObject<SocketClientDelegate>

-(void) start:(NSString*) deviceSN withUid:(NSString*)uid;
-(void) login;
-(void) logout;
-(void) stop;

@property (nonatomic, weak) id<TutkCommandManagerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
