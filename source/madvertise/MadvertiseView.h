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
#import <CoreLocation/CoreLocation.h>
#import "MadvertiseDelegationProtocol.h"

// enum of available banner formats
typedef enum tagMadvertiseAdClass {
  mma,medium_rectangle,leaderboard,fullscreen,portrait,landscape  
} MadvertiseAdClass;

@class InAppLandingPageController;
@class MadvertiseAd;

@interface MadvertiseView : UIView<UIWebViewDelegate> {
  
  // attributes
  InAppLandingPageController* inAppLandingPageController;
  UIViewController *rootViewController;
  id<MadvertiseDelegationProtocol> madDelegate;           // the delegate which receives ad related events like: adLoaded or adLoadFailed
  NSMutableData* receivedData;                            // data received thorugh the connection to the ad server
  NSMutableURLRequest* request;  
  NSURLConnection *conn;                                  // current request object
  
  MadvertiseAd* currentAd;                                          // current ad
  MadvertiseAdClass currentAdClass;                       // ad type
  
  NSInteger responseCode;                                 // flag that indicates if http response from ad server is ok
  bool isBannerMode;                                      // flag that indicates if the view shows a banner or a popup
  
  UIView* currentView;                                    // one of the two views above, depending on user action
  
  int visibleHolder;
  UIWebView* placeholder_1;
  UIWebView* placeholder_2;
  NSLock* lock;                                           // lock which is used to avoid race conditions while requesting an ad

  NSTimer* timer;                                         // the ad rotation timer
  double interval;                                        // interval of ad refresh
  int x, y;                                               // Position
  
  double animationDuration;
}


/////////////////
/// constructor
////////////////

@property (nonatomic, assign) id<MadvertiseDelegationProtocol> madDelegate;
@property (nonatomic, assign) UIViewController *rootViewController;
@property (nonatomic, retain) UIWebView *placeHolder1;
@property (nonatomic, retain) UIWebView *placeHolder2;
@property (nonatomic, retain) MadvertiseAd *currentAd;
@property (nonatomic, retain) InAppLandingPageController* inAppLandingPageController;
@property (nonatomic, retain) NSMutableURLRequest *request;
@property (nonatomic, retain) UIView *currentView;
@property (nonatomic, retain) NSTimer* timer;
@property (nonatomic, retain) NSURLConnection *conn;
@property (nonatomic, retain) NSMutableData* receivedData;


+ (MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)seconds;
+ (void) adLoadedHandlerWithObserver:(id) addObserver AndSelector:(SEL) sel;
+ (void) adLoadFailedHandlerWithObserver:(id) addObserver AndSelector:(SEL) sel;
- (void)place_at_x:(int)x_pos y:(int)y_pos;               // position the frame for the view


@end
