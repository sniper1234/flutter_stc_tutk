//
//  TutkClient.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 23/06/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class TutkClient;

@protocol TutkClientDelegate <NSObject>

- (void)tutkClient:(TutkClient*)client didReceiveVideoFrame:(char*) frameBuffer frameSize:(int) frameSize frameNumber:(int) frameNumber uid: (NSString*) uid deviceSN:(NSString*) deviceSN;

// ... other methods here
@end

@interface TutkClient : NSObject

- (void) startLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN;
- (void) stopLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN;

@property (nonatomic, weak) id<TutkClientDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
