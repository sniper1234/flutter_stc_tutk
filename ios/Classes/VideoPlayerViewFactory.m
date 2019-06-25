//
//  VideoPlayerViewFactory.m
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 22/06/19.
//

#import "VideoPlayerViewFactory.h"

@interface VideoPlayerViewFactory()
@end

@implementation VideoPlayerViewFactory
- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    VideoPlayerView* view =  [[VideoPlayerView alloc] initWithFrame:frame];
    self.videoPlayerView = view;
    return view;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    FlutterJSONMessageCodec* codec =  [[FlutterJSONMessageCodec alloc] init];
    return codec;
}
@end

