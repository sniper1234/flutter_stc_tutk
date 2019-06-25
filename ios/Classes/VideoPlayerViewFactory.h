//
//  VideoPlayerViewFactory.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 22/06/19.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "VideoPlayerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerViewFactory : NSObject<FlutterPlatformViewFactory>

@property (nonatomic) VideoPlayerView* videoPlayerView;

@end

NS_ASSUME_NONNULL_END
