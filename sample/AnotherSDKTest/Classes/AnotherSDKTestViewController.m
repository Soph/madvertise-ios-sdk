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

@implementation AnotherSDKTestViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  td = [[TestDelegate alloc] init];
  td2 = [[TestDelegate alloc] init];
  
  MadvertiseView* view = [MadvertiseView loadAdWithDelegate: td withClass:MMAAd secondsToRefresh:15];
  MadvertiseView* view2 = [MadvertiseView loadAdWithDelegate: td withClass:MMAAd secondsToRefresh:23];
  
  [view place_at_x:0 y:0];
  [view2 place_at_x:0 y:100];
  [self.view addSubview: view];
  
  [self.view addSubview: view2];
  [self.view bringSubviewToFront: view];
  [self.view bringSubviewToFront: view2];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (void)dealloc {
    [super dealloc];
}

@end
