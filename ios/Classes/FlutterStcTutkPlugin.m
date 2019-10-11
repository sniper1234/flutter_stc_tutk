#import "FlutterStcTutkPlugin.h"
#import "VideoPlayerViewFactory.h"
#import "TutkClientManager.h"
#import "VideoDecompressor.h"


@interface FlutterStcTutkPlugin()<TutkCientManagerDelegate>

@property (nonatomic, weak) VideoPlayerViewFactory* videoPlayerViewFactory;
@property (nonatomic) TutkClientManager* tutkClientManager;

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
    
    instance.tutkClientManager = [[TutkClientManager alloc] init];
    instance.tutkClientManager.delegate = instance;
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
    
    NSLog(@"FlutterStcTutkPlugin.startLiveVideo: uid=%@,deviceSN=%@", uid, deviceSN);
    [self.tutkClientManager startLiveVideo:uid deviceSN:deviceSN];
    
    return  @"success";
}

- (NSString*)stopLiveVideo:(NSString*) uid deviceSN:(NSString*) deviceSN {
    NSLog(@"FlutterStcTutkPlugin.stopLiveVideo: uid=%@,deviceSN=%@", uid, deviceSN);
    
    [self.tutkClientManager stopLiveVideo:uid deviceSN:deviceSN];
    return @"success";
}

- (void)tutkClientManager:(TutkClientManager*)manager didReceiveVideoFrame:(char*) frameBuffer frameSize:(int) frameSize frameNumber:(int) frameNumber uid: (NSString*) uid deviceSN:(NSString*) deviceSN {
    
    [self.videoPlayerViewFactory.videoPlayerView showFrame:(uint8_t*)frameBuffer withFrameSize:frameSize];
}

@end
