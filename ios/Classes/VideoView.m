//
//  VideoView.m
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 25/06/19.
//

#import "VideoView.h"

@interface VideoView()
@property (nonatomic, weak) AVSampleBufferDisplayLayer *videoLayer;
@end

@implementation VideoView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.videoLayer != nil) {
        self.videoLayer.frame = self.bounds;
    }
    
    // create our AVSampleBufferDisplayLayer and add it to the view
    AVSampleBufferDisplayLayer* layer = [[AVSampleBufferDisplayLayer alloc] init];
    layer.frame = self.bounds;
    layer.bounds = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    layer.backgroundColor = UIColor.grayColor.CGColor;
    
    // set Timebase, you may need this if you need to display frames at specific times
    // I didn't need it so I haven't verified that the timebase is working
    CMTimebaseRef controlTimebase;
    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase);
    
    //videoLayer.controlTimebase = controlTimebase;
    CMTimebaseSetTime(layer.controlTimebase, kCMTimeZero);
    CMTimebaseSetRate(layer.controlTimebase, 1.0);
    
    [[self layer] addSublayer:layer];
    
    self.videoLayer = layer;
}

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.videoLayer enqueueSampleBuffer:sampleBuffer];
}
@end
