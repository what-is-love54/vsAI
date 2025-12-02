//
//  RCTMicRecorder.m
//  vsAI
//
//  Created by The_VVoody on 02.12.2025.
//


#import "RCTMicRecorder.h"
#import <React/RCTLog.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <AVFoundation/AVFoundation.h>

#import <React-RCTAppDelegate/RCTDefaultReactNativeFactoryDelegate.h>

#import "vsAI-Swift.h"

@interface RCTMicRecorder ()
@property (nonatomic, strong) MicRecorder *swiftModule;
@end

@implementation RCTMicRecorder {
  MicRecorder *_micRecorder;
}

RCT_EXPORT_MODULE(NativeMicRecorder)

- (instancetype)init
{
  self = [super init];
  if (self) {
    // If you want singleton from Swift:
    // _swiftModule = [MicRecorder shared];
    _swiftModule = [[MicRecorder alloc] init];
  }
  return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeMicRecorderSpecJSI>(params);
}

- (void)start:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [self.swiftModule startRecordingWithCompletion:^(NSError * _Nullable error) {
    if (error) {
      reject(@"mic_start_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}

- (void)stop:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [self.swiftModule stopRecordingWithCompletion:^(NSError * _Nullable error) {
    if (error) {
      reject(@"mic_stop_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}


@end
