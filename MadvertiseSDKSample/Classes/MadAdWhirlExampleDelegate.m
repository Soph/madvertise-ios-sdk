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

#import "MadAdWhirlExampleDelegate.h"
#import "MadAdWhirlProtocol.h"
#import "MadLocation.h"



@implementation MadAdWhirlExampleDelegate


@synthesize controller        = _controller;
@synthesize animationType     = _ani_type;
@synthesize animationDuration = _ani_duration;
@synthesize selector          = _aSelector;
@synthesize selectorTarget    = _selectorTarget;


- (void) dealloc{
  [_controller release];
  [super dealloc];
}

- (id) initWithUIController:(UIViewController*) c{
  self = [super init];
  if(self){
     self.controller        = c;
     self.animationType     = curlDown;
     self.animationDuration = 2.0;
  }
  return self;
}

- (NSString *) appId{
  return  @"zZ9WCcXc";
}


- (void) triggerAdWhirlEvent{
  if(_aSelector != nil && _selectorTarget !=nil && [_selectorTarget respondsToSelector:_aSelector]){
    [_selectorTarget performSelector:_aSelector];
  }
}

- (NSString *)adWhirlApplicationKey{
  return @"ef0fdb6a2e6b4d2c9b77bff7d9686ea0";
}

- (UIViewController *)viewControllerForPresentingModalView{
  return self.controller;
}

- (bool) debugEnabled {
  return YES;
}

- (double) durationOfBannerAnimation{
  return _ani_duration;
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
  return @"25-35";
}

- (bool) downloadTrackerEnabled{
  return YES;
}

- (NSString *) gender{
  return @"M";
}

@end
