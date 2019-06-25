//
//  VideoPlayerView.m
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 22/06/19.
//

#import "VideoPlayerView.h"
#import "VideoDecompressor.h"
#import "VideoView.h"

@interface VideoPlayerView()<VideoDecompressorDelegate>
@property (nonatomic, weak) VideoView * videoView;
@property (nonatomic) VideoDecompressor * videoDecompressor;

@end

@implementation VideoPlayerView

-(instancetype) initWithFrame:(CGRect) frame {
    self = [super init];
    
    self.frame = frame;
    self.videoDecompressor = [[VideoDecompressor alloc] init];
    self.videoDecompressor.delegate = self;
    return self;
}

- (nonnull UIView *) view {
    if (self.videoView != nil) {
        return self.videoView;
    }
    
    VideoView* view = [[VideoView alloc] initWithFrame:self.frame];
    self.videoView = view;
    return view;
}

-(void) showFrame:(uint8_t*) frameBuffer withFrameSize:(uint32_t) frameSize {
    [self.videoDecompressor decompressVideoFrame:frameBuffer withSize:frameSize];
}

- (void)didOutputVideoFrameBuffer:(nonnull CMSampleBufferRef)sampleBuffer sender:(nonnull id)sender {
    [self.videoView enqueueSampleBuffer:sampleBuffer];
}

@end
