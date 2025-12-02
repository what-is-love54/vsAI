//
//  RCTMicRecorder.m
//  vsAI
//
//  Created by The_VVoody on 02.12.2025.
//


#import "RCTMicRecorder.h"
#import <React/RCTLog.h>

#import "vsAI-Swift.h"

@interface RCTMicRecorder ()
@property (nonatomic, strong) MicRecorder *swiftModule;
@end

@implementation RCTMicRecorder

RCT_EXPORT_MODULE(NativeMicRecorder)

- (instancetype)init
{
  self = [super init];
  if (self) {
    _swiftModule = [[MicRecorder alloc] init];
  }
  return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeMicRecorderSpecJSI>(params);
}

- (void)start:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
  [self.swiftModule start:^(NSError * _Nullable error) { // Call instance method
    if (error) {
      reject(@"mic_start_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}

- (void)stop:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
  [self.swiftModule stop:^(NSError * _Nullable error) { // Call instance method
    if (error) {
      reject(@"mic_stop_error", error.localizedDescription, error);
    } else {
      resolve(self.swiftModule.audioFileURL.absoluteString);
    }
  }];
}

@end
