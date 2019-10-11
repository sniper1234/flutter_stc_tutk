//
//  TutkClientManager.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 24/08/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class TutkClientManager;

@protocol TutkCientManagerDelegate <NSObject>

- (void)tutkClientManager:(TutkClientManager*)manager didReceiveVideoFrame:(char*) frameBuffer frameSize:(int) frameSize frameNumber:(int) frameNumber uid: (NSString*) uid deviceSN:(NSString*) deviceSN;

// ... other methods here
@end

@interface TutkClientManager : NSObject

@property (nonatomic, weak) id<TutkCientManagerDelegate> delegate;

- (void) startLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN;
- (void) stopLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN;


@end

NS_ASSUME_NONNULL_END
