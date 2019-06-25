//
//  VideoDecompressor.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 23/06/19.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VideoDecompressorDelegate <NSObject>

- (void)didOutputVideoFrameBuffer:(CMSampleBufferRef)sampleBuffer sender:(id) sender;

// ... other methods here
@end

@interface VideoDecompressor : NSObject

@property (nonatomic, weak) id<VideoDecompressorDelegate> delegate;
-(void) decompressVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize;

@end

NS_ASSUME_NONNULL_END
