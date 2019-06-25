//
//  NaluFrame.h
//  Sample_RDTAPIs
//
//  Created by Pengfei Chen on 20/06/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NaluFrame : NSObject

@property(nonatomic) uint8_t* frame;
@property(nonatomic) uint frameSize;

@end

NS_ASSUME_NONNULL_END
