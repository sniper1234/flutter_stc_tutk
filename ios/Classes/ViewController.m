//
//  rootController.m
//  Sample_AVAPIs
//
//  Created by tutk on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
//#import "Client.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "NaluFrame.h"

@interface ViewController ()

@property (nonatomic) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, weak) UIImageView* imageView;

@property (nonatomic) CMVideoFormatDescriptionRef formatDesc;
@property (nonatomic) AVSampleBufferDisplayLayer *videoLayer;
@property (nonatomic) int spsSize;
@property (nonatomic) int ppsSize;
@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView
{
    // If you create your views manually, you MUST override this method and use it to create your views.
    // If you use Interface Builder to create your views, then you must NOT override this method.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
//    Client *client = [[Client alloc] init];
//    client.delegate = self;
//    [client initialize];
//    [client login];
//    [client startLiveVideo];
    
//    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:imageView];
//    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    imageView.backgroundColor = UIColor.blueColor;
//    //[client start:@"ABXG1TRYG5PRSD1R111A"]; // Put your device's UID here.
//
    // create our AVSampleBufferDisplayLayer and add it to the view
    self.videoLayer = [[AVSampleBufferDisplayLayer alloc] init];
    self.videoLayer.frame = self.view.frame;
    self.videoLayer.bounds = self.view.bounds;
    self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    // set Timebase, you may need this if you need to display frames at specific times
    // I didn't need it so I haven't verified that the timebase is working
    CMTimebaseRef controlTimebase;
    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase);
    
    //videoLayer.controlTimebase = controlTimebase;
    CMTimebaseSetTime(self.videoLayer.controlTimebase, kCMTimeZero);
    CMTimebaseSetRate(self.videoLayer.controlTimebase, 1.0);
    
    [[self.view layer] addSublayer:self.videoLayer];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 300, 100, 30)];
    [button setTintColor: [UIColor blueColor]];
    [button setTitle:@"测试按钮" forState:UIControlStateNormal];
    [self.view addSubview:button];
}

- (void)didReceiveVideoFrame:(int )avIndex frameBuffer:(char*) buffer frameSize:(int) frameSize frameNumber:(int) frameNumber {
    
    
//    if (self.decompressionSession == nil) {
//        self.decompressionSession = [self createDecompSession];
//
////        CFAllocatorRef allocator = NULL;
////        CMVideoFormatDescriptionRef videoFormatDescription = NULL;
////        CFDictionaryRef videoDecoderSpecification = NULL;
////        CFDictionaryRef destinationImageBufferAttributes = NULL;
////        VTDecompressionSessionRef decompressionSessionOut;
////
////        OSStatus status = VTDecompressionSessionCreate(allocator, videoFormatDescription, videoDecoderSpecification, destinationImageBufferAttributes, NULL, &decompressionSessionOut);
////        NSLog(@"VTDecompressionSessionCreate: status=%d session=%@", (int)status, decompressionSessionOut);
////        self.decompressionSession = decompressionSessionOut;
//    }
    
//    NSArray* naluFrames = [self extractNaluFrame:(uint8_t*)buffer withSize:frameSize];
//    for (NaluFrame* naluFrame in naluFrames) {
//        [self receivedRawVideoFrame:naluFrame.frame withSize:naluFrame.frameSize isIFrame:1];
//    }
    
    [self receivedRawVideoFrame:(uint8_t*)buffer withSize:frameSize isIFrame:1];
}

-(void) createDecompSession
{
    // make sure to destroy the old VTD session
    _decompressionSession = NULL;
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = decompressionSessionDecodeFrameCallback;
    
    // this is necessary if you need to make calls to Objective C "self" from within in the callback method.
    callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
    
    // you can set some desired attributes for the destination pixel buffer.  I didn't use this but you may
    // if you need to set some attributes, be sure to uncomment the dictionary in VTDecompressionSessionCreate
    NSDictionary *destinationImageBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      [NSNumber numberWithBool:YES],
                                                      (id)kCVPixelBufferOpenGLESCompatibilityKey,
                                                      nil];
    
    OSStatus status =  VTDecompressionSessionCreate(NULL, _formatDesc, NULL,
                                                    NULL, // (__bridge CFDictionaryRef)(destinationImageBufferAttributes)
                                                    &callBackRecord, &_decompressionSession);
    NSLog(@"Video Decompression Session Create: \t %@", (status == noErr) ? @"successful!" : @"failed...");
    if(status != noErr) NSLog(@"\t\t VTD ERROR type: %d", (int)status);
}

void decompressionSessionDecodeFrameCallback(void *decompressionOutputRefCon,
                                             void *sourceFrameRefCon,
                                             OSStatus status,
                                             VTDecodeInfoFlags infoFlags,
                                             CVImageBufferRef imageBuffer,
                                             CMTime presentationTimeStamp,
                                             CMTime presentationDuration)
{
    
    ViewController *streamManager = (__bridge ViewController *)decompressionOutputRefCon;

    if (status != noErr)
    {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        NSLog(@"Decompressed error: %@", error);
    }
    else
    {
        NSLog(@"Decompressed sucessfully");

        // do something with your resulting CVImageBufferRef that is your decompressed frame
        [streamManager displayDecodedFrame:imageBuffer];
    }
}

-(void) displayDecodedFrame: (CVImageBufferRef) imageBuffer {
    
}

//-(VTDecompressionSessionRef) createDecompSession {
//
//    OSStatus status;
//    VTDecompressionSessionRef decoderDecompressionSession;
//
//    int tmpWidth = 400;
//    int tmpHeight = 300;
//    NSLog(@"Got new Width and Height from SPS - %dx%d", tmpWidth, tmpHeight);
//
//    CMFormatDescriptionRef decoderFormatDescription;
//
//    status = CMVideoFormatDescriptionCreate(NULL,
//                                            kCMVideoCodecType_H264,
//                                            tmpWidth,
//                                            tmpHeight,
//                                            NULL,
//                                            &decoderFormatDescription);
//
//    if (status == noErr)
//    {
//        // Set the pixel attributes for the destination buffer
//        CFMutableDictionaryRef destinationPixelBufferAttributes = CFDictionaryCreateMutable(
//                                                                                            NULL, // CFAllocatorRef allocator
//                                                                                            0,    // CFIndex capacity
//                                                                                            &kCFTypeDictionaryKeyCallBacks,
//                                                                                            &kCFTypeDictionaryValueCallBacks);
//
//        SInt32 destinationPixelType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
//        CFDictionarySetValue(destinationPixelBufferAttributes,kCVPixelBufferPixelFormatTypeKey, CFNumberCreate(NULL, kCFNumberSInt32Type, &destinationPixelType));
//        CFDictionarySetValue(destinationPixelBufferAttributes,kCVPixelBufferWidthKey, CFNumberCreate(NULL, kCFNumberSInt32Type, &tmpWidth));
//        CFDictionarySetValue(destinationPixelBufferAttributes, kCVPixelBufferHeightKey, CFNumberCreate(NULL, kCFNumberSInt32Type, &tmpHeight));
//        CFDictionarySetValue(destinationPixelBufferAttributes, kCVPixelBufferOpenGLCompatibilityKey, kCFBooleanTrue);
//
//        // Set the Decoder Parameters
//        CFMutableDictionaryRef decoderParameters = CFDictionaryCreateMutable(
//                                                                             NULL, // CFAllocatorRef allocator
//                                                                             0,    // CFIndex capacity
//                                                                             &kCFTypeDictionaryKeyCallBacks,
//                                                                             &kCFTypeDictionaryValueCallBacks);
//
//        CFDictionarySetValue(decoderParameters,kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
//
//        // Create the decompression session
//        // Throws Error -8971 (codecExtensionNotFoundErr)
//        status = VTDecompressionSessionCreate(NULL, decoderFormatDescription, decoderParameters, destinationPixelBufferAttributes, NULL, &decoderDecompressionSession);
//
//
//        // release the dictionaries
//        CFRelease(destinationPixelBufferAttributes);
//        CFRelease(decoderParameters);
//
//        // Check the Status
//        if(status != noErr)
//        {
//            NSLog(@"Error %d while creating Video Decompression Session.", (int)status);
//        }
//    }
//    else
//    {
//        NSLog(@"Error %d while creating Video Format Descripttion.", (int)status);
//    }
//
//    return decoderDecompressionSession;
//}

NSString * const naluTypesStrings[] =
{
    @"0: Unspecified (non-VCL)",
    @"1: Coded slice of a non-IDR picture (VCL)",    // P frame
    @"2: Coded slice data partition A (VCL)",
    @"3: Coded slice data partition B (VCL)",
    @"4: Coded slice data partition C (VCL)",
    @"5: Coded slice of an IDR picture (VCL)",      // I frame
    @"6: Supplemental enhancement information (SEI) (non-VCL)",
    @"7: Sequence parameter set (non-VCL)",         // SPS parameter
    @"8: Picture parameter set (non-VCL)",          // PPS parameter
    @"9: Access unit delimiter (non-VCL)",
    @"10: End of sequence (non-VCL)",
    @"11: End of stream (non-VCL)",
    @"12: Filler data (non-VCL)",
    @"13: Sequence parameter set extension (non-VCL)",
    @"14: Prefix NAL unit (non-VCL)",
    @"15: Subset sequence parameter set (non-VCL)",
    @"16: Reserved (non-VCL)",
    @"17: Reserved (non-VCL)",
    @"18: Reserved (non-VCL)",
    @"19: Coded slice of an auxiliary coded picture without partitioning (non-VCL)",
    @"20: Coded slice extension (non-VCL)",
    @"21: Coded slice extension for depth view components (non-VCL)",
    @"22: Reserved (non-VCL)",
    @"23: Reserved (non-VCL)",
    @"24: STAP-A Single-time aggregation packet (non-VCL)",
    @"25: STAP-B Single-time aggregation packet (non-VCL)",
    @"26: MTAP16 Multi-time aggregation packet (non-VCL)",
    @"27: MTAP24 Multi-time aggregation packet (non-VCL)",
    @"28: FU-A Fragmentation unit (non-VCL)",
    @"29: FU-B Fragmentation unit (non-VCL)",
    @"30: Unspecified (non-VCL)",
    @"31: Unspecified (non-VCL)",
};

-(NSArray*) extractNaluFrame:(uint8_t *)frame
                withSize:(uint32_t)frameSize  {
    NSMutableArray* naluFrameList  = [[NSMutableArray alloc] init];
    int firstStartCodeIndex = 0;
    int secondStartCodeIndex = 0;
    
    // find start code index
    for (int i = 0; i < frameSize; i++) {
        if (frame[i] == 0x00 && frame[i+1] == 0x00 && frame[i+2] == 0x00 && frame[i+3] == 0x01)
        {
            firstStartCodeIndex = i;
            break;
        }
    }
    
    // extract frames
    for (int i = firstStartCodeIndex + 4; i < frameSize; i++) {
        if (frame[i] == 0x00 && frame[i+1] == 0x00 && frame[i+2] == 0x00 && frame[i+3] == 0x01)
        {
            secondStartCodeIndex = i;
            NaluFrame* naluFrame = [[NaluFrame alloc] init];
            naluFrame.frame = &frame[i];
            naluFrame.frameSize = secondStartCodeIndex - firstStartCodeIndex;
            [naluFrameList addObject:naluFrame];

            firstStartCodeIndex = secondStartCodeIndex;
        }
    }
    
    // extract last frame
    if (firstStartCodeIndex < frameSize ) {
        NaluFrame* naluFrame = [[NaluFrame alloc] init];
        naluFrame.frame = &frame[firstStartCodeIndex];
        naluFrame.frameSize = frameSize - firstStartCodeIndex;
        [naluFrameList addObject:naluFrame];
    }

    return naluFrameList;
}

-(void) receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize isIFrame:(int)isIFrame
{
    OSStatus status;
    
    uint8_t *data = NULL;
    uint8_t *pps = NULL;
    uint8_t *sps = NULL;
    
    // I know what my H.264 data source's NALUs look like so I know start code index is always 0.
    // if you don't know where it starts, you can use a for loop similar to how i find the 2nd and 3rd start codes
    int startCodeIndex = 0;
    int secondStartCodeIndex = 0;
    int thirdStartCodeIndex = 0;
    
    long blockLength = 0;
    
    CMSampleBufferRef sampleBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    
    int nalu_type = (frame[startCodeIndex + 4] & 0x1F);
    NSLog(@"~~~~~~~ Received NALU Type \"%@\" ~~~~~~~~", naluTypesStrings[nalu_type]);
    
    // if we havent already set up our format description with our SPS PPS parameters, we
    // can't process any frames except type 7 that has our parameters
    if (nalu_type != 7 && _formatDesc == NULL)
    {
        NSLog(@"Video error: Frame is not an I Frame and format description is null");
        return;
    }
    
    // NALU type 7 is the SPS parameter NALU
    if (nalu_type == 7)
    {
        // find where the second PPS start code begins, (the 0x00 00 00 01 code)
        // from which we also get the length of the first SPS code
        for (int i = startCodeIndex + 4; i < startCodeIndex + 40; i++)
        {
            if (frame[i] == 0x00 && frame[i+1] == 0x00 && frame[i+2] == 0x00 && frame[i+3] == 0x01)
            {
                secondStartCodeIndex = i;
                _spsSize = secondStartCodeIndex;   // includes the header in the size
                break;
            }
        }
        
        // find what the second NALU type is
        nalu_type = (frame[secondStartCodeIndex + 4] & 0x1F);
        NSLog(@"~~~~~~~ Received NALU Type \"%@\" ~~~~~~~~", naluTypesStrings[nalu_type]);
    }
    
    // type 8 is the PPS parameter NALU
    if(nalu_type == 8)
    {
        // find where the NALU after this one starts so we know how long the PPS parameter is
        for (int i = _spsSize + 4; i < _spsSize + 30; i++)
        {
            if (frame[i] == 0x00 && frame[i+1] == 0x00 && frame[i+2] == 0x00 && frame[i+3] == 0x01)
            {
                thirdStartCodeIndex = i;
                _ppsSize = thirdStartCodeIndex - _spsSize;
                break;
            }
        }
        
        // if there is no third start code index, then the rest of buffer is pps
        if (_ppsSize == 0) {
            _ppsSize = frameSize - _spsSize;
        }
        
        // allocate enough data to fit the SPS and PPS parameters into our data objects.
        // VTD doesn't want you to include the start code header (4 bytes long) so we add the - 4 here
        sps = malloc(_spsSize - 4);
        pps = malloc(_ppsSize - 4);
        
        // copy in the actual sps and pps values, again ignoring the 4 byte header
        memcpy (sps, &frame[4], _spsSize-4);
        memcpy (pps, &frame[_spsSize+4], _ppsSize-4);
        
        // now we set our H264 parameters
        uint8_t*  parameterSetPointers[2] = {sps, pps};
        size_t parameterSetSizes[2] = {_spsSize-4, _ppsSize-4};
        
        // suggestion from @Kris Dude's answer below
        if (_formatDesc)
        {
            CFRelease(_formatDesc);
            _formatDesc = NULL;
        }
        
        status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2,
                                                                     (const uint8_t *const*)parameterSetPointers,
                                                                     parameterSetSizes, 4,
                                                                     &_formatDesc);
        
        NSLog(@"\t\t Creation of CMVideoFormatDescription: %@", (status == noErr) ? @"successful!" : @"failed...");
        if(status != noErr) NSLog(@"\t\t Format Description ERROR type: %d", (int)status);
        
        // See if decomp session can convert from previous format description
        // to the new one, if not we need to remake the decomp session.
        // This snippet was not necessary for my applications but it could be for yours
        /*BOOL needNewDecompSession = (VTDecompressionSessionCanAcceptFormatDescription(_decompressionSession, _formatDesc) == NO);
         if(needNewDecompSession)
         {
         [self createDecompSession];
         }*/
        
        // now lets handle the IDR frame that (should) come after the parameter sets
        // I say "should" because that's how I expect my H264 stream to work, YMMV
        if (thirdStartCodeIndex > 0) {
            nalu_type = (frame[thirdStartCodeIndex + 4] & 0x1F);
            NSLog(@"~~~~~~~ Received NALU Type \"%@\" ~~~~~~~~", naluTypesStrings[nalu_type]);
        }
    }
    
    // create our VTDecompressionSession.  This isnt neccessary if you choose to use AVSampleBufferDisplayLayer
    if((status == noErr) && (_decompressionSession == NULL))
    {
        [self createDecompSession];
    }
    
    // type 5 is an IDR frame NALU.  The SPS and PPS NALUs should always be followed by an IDR (or IFrame) NALU, as far as I know
    if(nalu_type == 5)
    {
        // find the offset, or where the SPS and PPS NALUs end and the IDR frame NALU begins
        int offset = _spsSize + _ppsSize;
        blockLength = frameSize - offset;
        data = malloc(blockLength);
        data = memcpy(data, &frame[offset], blockLength);
        
        // replace the start code header on this NALU with its size.
        // AVCC format requires that you do this.
        // htonl converts the unsigned int from host to network byte order
        uint32_t dataLength32 = htonl (blockLength - 4);
        memcpy (data, &dataLength32, sizeof (uint32_t));
        
        // create a block buffer from the IDR NALU
        status = CMBlockBufferCreateWithMemoryBlock(NULL, data,  // memoryBlock to hold buffered data
                                                    blockLength,  // block length of the mem block in bytes.
                                                    kCFAllocatorNull, NULL,
                                                    0, // offsetToData
                                                    blockLength,   // dataLength of relevant bytes, starting at offsetToData
                                                    0, &blockBuffer);
        
        NSLog(@"\t\t BlockBufferCreation: \t %@", (status == kCMBlockBufferNoErr) ? @"successful!" : @"failed...");
    }
    
    // NALU type 1 is non-IDR (or PFrame) picture
    if (nalu_type == 1)
    {
        // non-IDR frames do not have an offset due to SPS and PSS, so the approach
        // is similar to the IDR frames just without the offset
        blockLength = frameSize;
        data = malloc(blockLength);
        data = memcpy(data, &frame[0], blockLength);
        
        // again, replace the start header with the size of the NALU
        uint32_t dataLength32 = htonl (blockLength - 4);
        memcpy (data, &dataLength32, sizeof (uint32_t));
        
        status = CMBlockBufferCreateWithMemoryBlock(NULL, data,  // memoryBlock to hold data. If NULL, block will be alloc when needed
                                                    blockLength,  // overall length of the mem block in bytes
                                                    kCFAllocatorNull, NULL,
                                                    0,     // offsetToData
                                                    blockLength,  // dataLength of relevant data bytes, starting at offsetToData
                                                    0, &blockBuffer);
        
        NSLog(@"\t\t BlockBufferCreation: \t %@", (status == kCMBlockBufferNoErr) ? @"successful!" : @"failed...");
    }
    
    // now create our sample buffer from the block buffer,
    if(status == noErr)
    {
        // here I'm not bothering with any timing specifics since in my case we displayed all frames immediately
        const size_t sampleSize = blockLength;
        status = CMSampleBufferCreate(kCFAllocatorDefault,
                                      blockBuffer, true, NULL, NULL,
                                      _formatDesc, 1, 0, NULL, 1,
                                      &sampleSize, &sampleBuffer);
        
        NSLog(@"\t\t SampleBufferCreate: \t %@", (status == noErr) ? @"successful!" : @"failed...");
    }
    
    if(status == noErr)
    {
        // set some values of the sample buffer's attachments
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        
        // either send the samplebuffer to a VTDecompressionSession or to an AVSampleBufferDisplayLayer
        [self render:sampleBuffer];
    }
    
    // free memory to avoid a memory leak, do the same for sps, pps and blockbuffer
    if (NULL != data)
    {
        free (data);
        data = NULL;
    }
}

//-(void) render: (CMSampleBufferRef) buffer {
//    VTDecompressionSessionRef session = self.decompressionSession;
//    CMSampleBufferRef sampleBuffer = buffer;
//    VTDecodeFrameFlags decodeFlags = kVTDecodeFrame_EnableAsynchronousDecompression; // bit 0 is enableAsynchronousDecompression
//    VTDecodeInfoFlags infoFlagsOut;
//
//    OSStatus status = VTDecompressionSessionDecodeFrameWithOutputHandler(session, sampleBuffer, decodeFlags, &infoFlagsOut, ^(OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration) {
//        NSLog(@"VTDecompressionSessionDecodeFrameWithOutputHandler: status=%d infoFlags=%u, imageBuffer=%@", (int)status, (unsigned int)infoFlags, imageBuffer);
//    });
//    NSLog(@"VTDecompressionSessionDecodeFrameWithOutputHandler return status=%d", (int)status);
//}

- (void) render:(CMSampleBufferRef)sampleBuffer
{
    VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
    VTDecodeInfoFlags flagOut;
    NSDate* currentTime = [NSDate date];
    VTDecompressionSessionDecodeFrame(_decompressionSession, sampleBuffer, flags,
                                      (void*)CFBridgingRetain(currentTime), &flagOut);
    
    // if you're using AVSampleBufferDisplayLayer, you only need to use this line of code
    [self.videoLayer enqueueSampleBuffer:sampleBuffer];
    CFRelease(sampleBuffer);
}

@end
