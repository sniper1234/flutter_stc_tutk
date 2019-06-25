#import "FlutterStcTutkPlugin.h"
#import "VideoPlayerViewFactory.h"
#import "TutkClient.h"
#import "VideoDecompressor.h"


@interface FlutterStcTutkPlugin()<TutkClientDelegate>

@property (nonatomic, weak) VideoPlayerViewFactory* videoPlayerViewFactory;
@property (nonatomic) TutkClient* tutkClient;

@end

@implementation FlutterStcTutkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_stc_tutk"
            binaryMessenger:[registrar messenger]];
    FlutterStcTutkPlugin* instance = [[FlutterStcTutkPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    VideoPlayerViewFactory* factory = [[VideoPlayerViewFactory alloc] init];
    [registrar registerViewFactory:factory withId:@"stc_video_player_view"];
    instance.videoPlayerViewFactory = factory;
    
    instance.tutkClient = [[TutkClient alloc] init];
    instance.tutkClient.delegate = instance;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"startLiveVideo" isEqualToString:call.method]) {
      NSDictionary* args = (NSDictionary*)call.arguments;
      NSString* uid = [args objectForKey:@"uid"];
      NSString* deviceSN = [args objectForKey:@"deviceSN"];
      NSString* resultMessage = [self startLiveVideo:uid deviceSN:deviceSN];
      result(resultMessage);
  } else if ([@"stopLiveVideo" isEqualToString:call.method]) {
      NSDictionary* args = (NSDictionary*)call.arguments;
      NSString* uid = [args objectForKey:@"uid"];
      NSString* deviceSN = [args objectForKey:@"deviceSN"];
      NSString* resultMessage = [self stopLiveVideo:uid deviceSN:deviceSN];
      result(resultMessage);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (NSString*)startLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN {
    
    [self.tutkClient startLiveVideo:uid deviceSN:deviceSN];
    
    NSLog(@"startLiveVideo uid:%@ deviceSN:%@", uid, deviceSN);
    return  @"success";
}

- (NSString*)stopLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN {
    NSLog(@"stopLiveVideo uid:%@ deviceSN:%@", uid, deviceSN);
    
    [self.tutkClient stopLiveVideo:uid deviceSN:deviceSN];
    return @"success";
}

-(void)tutkClient:(TutkClient *)client didReceiveVideoFrame:(char *)frameBuffer frameSize:(int)frameSize frameNumber:(int)frameNumber uid:(NSString *)uid deviceSN:(NSString *)deviceSN {
    [self.videoPlayerViewFactory.videoPlayerView showFrame:(uint8_t*)frameBuffer withFrameSize:frameSize];
}

@end
