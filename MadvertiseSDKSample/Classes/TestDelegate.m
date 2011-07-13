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

#import "TestDelegate.h"

@implementation TestDelegate 

@synthesize animationType     = _ani_type;
@synthesize animationDuration = _ani_duration;

- (void) dealloc{
  [super dealloc];
}

- (id) init{
  self = [super init];
  if(self){
    self.animationType     = curlDown;
    self.animationDuration = 2.0;
  }
  return self;
}

#pragma mark -
#pragma mark MadvertiseDelegateProtocol Methods

- (NSString *) appId {
  return @"zZ9WCcXc";
}

- (bool) debugEnabled {
  return true;
}

- (double) durationOfBannerAnimation{
  return self.animationDuration;
}

- (MadvertiseAnimationClass) bannerAnimationTyp{
  return self.animationType;
}

- (MadLocation*) location {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  MadLocation *aLocation = [[MadLocation alloc] initWithLatiude:8.807081 andLongitude:53.074981 andPrecision:city];
  return aLocation;
  [pool release];
}

- (NSString*)age {
  return @"0-120";
}

- (bool) downloadTrackerEnabled{
  return YES;
}

- (NSString *) gender{
  return @"M";
}

@end
