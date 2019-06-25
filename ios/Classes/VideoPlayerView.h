//
//  VideoPlayerView.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 22/06/19.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerView : NSObject<FlutterPlatformView>

@property (nonatomic) CGRect frame;

-(instancetype) initWithFrame:(CGRect) frame;
-(void) showFrame:(uint8_t*) frameBuffer withFrameSize:(uint32_t) frameSize;

@end

NS_ASSUME_NONNULL_END
