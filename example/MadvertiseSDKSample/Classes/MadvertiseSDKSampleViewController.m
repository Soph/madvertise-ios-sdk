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

#import "MadvertiseSDKSampleViewController.h"
#import "MadvertiseView.h"
#import "MadvertiseSDKSampleDelegate.h"
#import "MadvertiseTracker.h"
#import "MadvertiseUtilities.h"

@implementation MadvertiseSDKSampleViewController


- (void)dealloc {
  if(madvertiseDemoDelegate)
    [madvertiseDemoDelegate release];
  [super dealloc];
}


- (void)viewDidLoad {
  [super viewDidLoad];

  madvertiseDemoDelegate = [[MadvertiseSDKSampleDelegate alloc] init];
  MadvertiseView *ad = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:medium_rectangle secondsToRefresh:15];
  [ad place_at_x:0 y:60];
  [self.view addSubview:ad];
  [self.view bringSubviewToFront:ad];
  
  MadvertiseView *ad2 = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:leaderboard secondsToRefresh:25];
  [ad2 place_at_x:0 y:140];
  [self.view addSubview:ad2];
  [self.view bringSubviewToFront:ad2];
  
  
  MadvertiseView *ad3 = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:portrait secondsToRefresh:25];
  [ad3 place_at_x:0 y:320];
  [self.view addSubview:ad3];
  [self.view bringSubviewToFront:ad3];
  
  
  ad3 = [MadvertiseView loadAdWithDelegate:madvertiseDemoDelegate withClass:fullscreen secondsToRefresh:25];
  [ad3 place_at_x:0 y:420];
  [self.view addSubview:ad3];
  [self.view bringSubviewToFront:ad3];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


#pragma mark - 
#pragma mark Notifications

- (void) onAdLoadedSuccessfully:(NSNotification*)notify{
  MADLog(@"successfully loaded with code: %@",[notify object]);
}

- (void) onAdLoadedFailed:(NSNotification*)notify{
  MADLog(@"ad load faild with code: %@",[notify object]);
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
