// Copyright 2011 madvertise Mobile Advertising GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MadvertiseSDKSampleDelegate.h"

@implementation MadvertiseSDKSampleDelegate 

#pragma mark -
#pragma mark MadvertiseDelegateProtocol Methods

- (NSString *) appId {
  return @"TestTokn";
//  return @"EIt5zves";
}

- (BOOL) debugEnabled {
  return YES;
}

- (double) durationOfBannerAnimation{
  return 2.0;
}

- (MadvertiseAnimationClass) bannerAnimationTyp{
// topToBottom:
// curlDown:
// fade:
  return leftToRight;
}

//- (NSString*) adServer {
//  return @"http://192.168.1.51:9292";
//}

- (CLLocationCoordinate2D) location {
    CLLocationCoordinate2D _location = { 8.807081, 53.074981 };
    return _location;
}

- (BOOL) downloadTrackerEnabled {
  return YES;
}

- (NSString*)age {
  return @"21";
}

- (NSString *) gender {
  return @"M";
}

@end
