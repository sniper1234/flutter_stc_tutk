//
//  Client.h
//  Sample_AVAPIs
//
//  Created by tutk on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RDTClientDelegate <NSObject>

- (void)didReceiveVideoFrame:(int )avIndex frameBuffer:(char*) buffer frameSize:(int) frameSize frameNumber:(int) frameNumber;

// ... other methods here
@end

@interface Client : NSObject

- (void) initialize;
- (void) login;
- (void) startLiveVideo;

@property (nonatomic, weak) id<RDTClientDelegate> delegate;

@end

