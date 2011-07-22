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

#import "AnotherSDKTestViewController.h"
#import "MadvertiseView.h"
#import "AdWhirlView.h"
#import "TestDelegate.h"

@implementation AnotherSDKTestViewController


- (void)dealloc {
  [_animationPicker release];
  [_bannerPicker release];
  [_aDelegate release];
  [super dealloc];
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  // MadAdWhirlProtocol Example
  //===========================
  _aDelegate            = [[MadAdWhirlExampleDelegate alloc] initWithUIController:self];
  
  
  // MadvertiseDelegationProtocol Example
  //=====================================
  //_aDelegate          = [[TestDelegate alloc] init]; 
  
  
  //possible Formats
  //================
  // IABAd | MMAAd | leaderboard | full_screen | portrait | landscape | all

  
  MadvertiseView *madView = [MadvertiseView loadAdWithDelegate: _aDelegate withClass:MMAAd secondsToRefresh:15];
  [self.view addSubview:madView];
  [madView place_at_x:0 y:60];
  [self.view bringSubviewToFront: madView];
  [madView release];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


#pragma mark - 
#pragma mark Notifications

- (void) onAdLoadedSuccessfully:(NSNotification*)notify{
  [MadDebug localDebug: [NSString stringWithFormat:@"successfully loaded with code: %@",[notify object]]];
}

- (void) onAdLoadedFailed:(NSNotification*)notify{
  [MadDebug localDebug: [NSString stringWithFormat:@"ad load faild with code: %@",[notify object]]];
}

- (void) viewWillAppear:(BOOL)animated{
  
  //observing adLoaded and adLoadFailed Events
  //==========================================
  
  [MadvertiseView adLoadedHandlerWithObserver:self AndSelector:@selector(onAdLoadedSuccessfully:)];
  [MadvertiseView adLoadFailedHandlerWithObserver:self AndSelector:@selector(onAdLoadedFailed:)];
}

- (void) viewWillDisappear:(BOOL)animated{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
