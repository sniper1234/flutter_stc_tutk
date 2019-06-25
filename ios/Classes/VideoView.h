//
//  VideoView.h
//  flutter_stc_tutk
//
//  Created by Pengfei Chen on 25/06/19.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoView : UIView
- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
