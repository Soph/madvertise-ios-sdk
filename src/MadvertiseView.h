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

#import <UIKit/UIKit.h>
#import "MadvertiseDelegationProtocol.h"
#import "MadDebug.h"
#import "Ad.h"
#import "InAppLandingPageController.h"


typedef enum tagMadvertiseAdClass {
  IABAd,
  MMAAd
} MadvertiseAdClass;

@interface MadvertiseView : UIView<UIWebViewDelegate> {
  // the delegate which receives ad related events like: adLoaded or adLoadFailed
  id<MadvertiseDelegationProtocol> madDelegate;
  
  // data received thorugh the connection to the ad server
  NSMutableData* receivedData;
  
  // current request object
  NSMutableURLRequest* request;
  
  // current ad
  Ad* currentAd;
  
  // flag that indicates if http response from ad server is ok
  bool responseCodeOK;
  
  // flag that indicates if the view shows a banner or a popup
  bool isBannerMode;
  
  // one of the two views above, depending on user action
  UIView* currentView;
  UIView* oldView; 
  
  // lock which is used to avoid race conditions while requesting an ad
  NSLock* lock;
  
  // the ad rotation timer
  NSTimer* timer;
  
  // ad type
  MadvertiseAdClass currentAdClass;

  InAppLandingPageController* inAppLandingPageController;
  
  // interval of ad refresh
  double interval;
  
  int x, y;

}

+ (MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)seconds;

// load a new ad into an existing MadvertiseView 
// Ads should not be cached, nor should you request more than one ad per minute
- (void)loadAd;

// position the frame for the view
-(void)place_at_x:(int)x_pos y:(int)y_pos;

// only used internally

- (MadvertiseView*)initWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh;

- (void)createAdReloadTimer;

- (NSString*)getIP;

- (void) displayView;

@end
