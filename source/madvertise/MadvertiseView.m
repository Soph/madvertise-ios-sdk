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


#import <netinet/in.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

#import "MadvertiseUtilities.h"


#import "MadvertiseAd.h"
#import "InAppLandingPageController.h"
#import "MadvertiseTextAdView.h"
#import "MadvertiseTracker.h"
#import "MadvertiseView.h"
#import "CJSONDeserializer.h"

#define MADVERTISE_SDK_VERION @"4.1.3"



// PRIVATE METHODS

@interface MadvertiseView ()
- (CGSize) getScreenResolution;
- (CGSize) getParentViewDimensions;
- (NSString*) getDeviceOrientation;
- (void)destroyView:(UIView*) inView;
- (MadvertiseView*)initWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh;
- (void)swapViewWithCurlDownAnimation:(UIView*)view;
- (void) swapViewWithoutAnimation:(UIView*)aWebView;
- (void) swapViewFormTopToBottom;
- (void) swapViewFormLeftToRight;
- (void) swapViewWithFading;
- (void) createAdReloadTimer;
- (void) displayView;
- (void) stopTimer;
- (void)loadAd;       // load a new ad into an existing MadvertiseView 
                      // Ads should not be cached, nor should you request more than one ad per minute
@end


@implementation MadvertiseView

@synthesize placeHolder1 = placeholder_1;
@synthesize placeHolder2 = placeholder_2;
@synthesize currentAd;
@synthesize inAppLandingPageController;
@synthesize request;
@synthesize currentView;
@synthesize timer;
@synthesize conn;
@synthesize receivedData;
@synthesize madDelegate;
@synthesize rootViewController;

NSString * const MadvertiseAdClass_toString[] = {
  @"mma",
  @"medium_rectangle",
  @"leaderboard",
  @"fullscreen",
  @"portrait",
  @"landscape"
};

// METHODS
- (void) dealloc {
  MADLog(@"Call dealloc in MadvertiseView");
  
  [self.conn cancel];
  self.conn = nil;
  self.request = nil;
  self.receivedData = nil;
  self.rootViewController = nil;
  
  [self stopTimer];
  self.timer = nil;
  
  self.inAppLandingPageController = nil;
  self.madDelegate = nil;
  
  self.placeHolder1.delegate = nil;
  [self.placeHolder1 stopLoading];
  self.placeHolder1 = nil;
  self.placeHolder2.delegate = nil;
  [self.placeHolder2 stopLoading];
  self.placeHolder2 = nil;
  
  self.currentView = nil;
  self.currentAd   = nil;
  
  [lock release];
  lock = nil;
     
  [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationDidBecomeActiveNotification object:nil];


  [super dealloc];
}

//////////////////////
// main-constructor //
//////////////////////

+ (MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh {

  BOOL enableDebug = NO;
  
#ifdef DEBUG
  enableDebug = YES;
#endif
  
  // debugging
  if([delegate respondsToSelector:@selector(debugEnabled)]){
    enableDebug = [delegate debugEnabled];
  }
  
  // Download-Tracker
  if([delegate respondsToSelector:@selector(downloadTrackerEnabled)]){
    if([delegate downloadTrackerEnabled] == YES){
      [MadvertiseTracker setDebugMode: enableDebug];
      [MadvertiseTracker setProductToken:[delegate appId]];
      [MadvertiseTracker enable];
    }
  }
  return [[[MadvertiseView alloc] initWithDelegate:delegate withClass:adClassValue secondsToRefresh:secondsToRefresh] autorelease];
}

+ (void) adLoadedHandlerWithObserver:(id) observer AndSelector:(SEL) selector{
  [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"MadvertiseAdLoaded" object:nil];
}

+ (void) adLoadFailedHandlerWithObserver:(id) observer AndSelector:(SEL) selector{
  [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"MadvertiseAdLoadFailed" object:nil];
}

- (void)removeFromSuperview {
  [self stopTimer];

  [placeholder_1 removeFromSuperview];
  [placeholder_2 removeFromSuperview];
  [super removeFromSuperview];
}

- (void)place_at_x:(int)x_pos y:(int)y_pos {
 
  x = x_pos;
  y = y_pos;
  
  if(currentAdClass == medium_rectangle) {
    self.frame = CGRectMake(x_pos, y_pos, 300, 250);
  } else if(currentAdClass == mma) {
    self.frame = CGRectMake(x_pos, y_pos, 320, 53);
  } else if(currentAdClass == leaderboard){
    self.frame = CGRectMake(x_pos, y_pos, 728, 90);
  } else if(currentAdClass == fullscreen){
    self.frame = CGRectMake(x_pos, y_pos, 768, 768);
  } else if(currentAdClass == portrait){
    self.frame = CGRectMake(x_pos, y_pos, 766, 66);
  } else if(currentAdClass == landscape){
    self.frame = CGRectMake(x_pos, y_pos, 1024, 66);
  }
}

// helper method for initialization
- (MadvertiseView*)initWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh {
  
  if ((self = [super init])) {
    self.clipsToBounds = YES; 
    
    currentAdClass     = adClassValue;
    
    MADLog(@"*** madvertise SDK %@ ***", MADVERTISE_SDK_VERION);
    
    interval            = secondsToRefresh;
    request             = nil;
    receivedData        = nil;
    responseCode        = 200;
    isBannerMode        = YES;
    timer               = nil;
    
    // [self createAdReloadTimer];
    
    madDelegate  = delegate;
    
    // load first ad
    lock = [[NSLock alloc] init];
    [self loadAd];
    [self createAdReloadTimer];
    
    placeholder_1 = [[UIWebView alloc] initWithFrame:CGRectZero];
    [placeholder_1 setUserInteractionEnabled:NO];  
    placeholder_1.delegate = self;
    
    placeholder_2 = [[UIWebView alloc] initWithFrame:CGRectZero];
    [placeholder_2 setUserInteractionEnabled:NO];  
    placeholder_2.delegate = self;
    
    visibleHolder     = 0;
    animationDuration = 0.75;
    
    if([madDelegate respondsToSelector:@selector(durationOfBannerAnimation)]){
      animationDuration = [madDelegate durationOfBannerAnimation];
    }
    
    //Notification
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(stopTimer) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(createAdReloadTimer) name:UIApplicationDidBecomeActiveNotification object:nil];
  }
  
  return self;
}


#pragma mark - server connection handling

// check, if response is OK
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
  MADLog(@"%@ %i", @"Received response code: ", [response statusCode]);
  responseCode = [response statusCode];
  [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  MADLog(@"Received data from Ad Server");
  [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  MADLog(@"Failed to receive ad");
  MADLog(@"%@",[error description]);
  
  // dispatch status notification
  //-----------------------------
  [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoadFailed" object:[NSNumber numberWithInt:responseCode]];

  self.request = nil;
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
  return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  
  if( responseCode == 200) {
    // parse response
    MADLog(@"Deserializing JSON");
    NSString* jsonString = [[NSString alloc] initWithData:receivedData encoding: NSUTF8StringEncoding];
    MADLog(@"Received string: %@", jsonString);
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    [jsonString release];
    
    NSDictionary *dictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    
    MADLog(@"Creating ad");
    
    self.currentAd = [[[MadvertiseAd alloc] initFromDictionary:dictionary] autorelease];
    
    // banner formats
    if(currentAdClass == medium_rectangle) {
      currentAd.width   = 300;
      currentAd.height  = 250;
    } else if(currentAdClass == mma) {
      currentAd.width   = 320;
      currentAd.height  = 53; 
    } else if(currentAdClass == leaderboard){
      currentAd.width   = 728;
      currentAd.height  = 90;
    } else if(currentAdClass == fullscreen){
      currentAd.width   = 768;
      currentAd.height  = 768;
    } else if(currentAdClass == portrait){
      currentAd.width   = 766;
      currentAd.height  = 66;
    } else if(currentAdClass == landscape){
      currentAd.width   = 1024;
      currentAd.height  = 66;
    }
    [self displayView];
    
  } else {
    // dispatch status notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoadFailed" object:[NSNumber numberWithInt:responseCode]];
  }
  
  self.request = nil;
  self.receivedData = nil;
}


// generate request, that is send to the ad server
- (void)loadAd {
  
  [lock lock];
  
  if(self.request){
    MADLog(@"loadAd - returning because another request is running");
    [lock unlock];
    return;
  }
  
  NSString *server_url = @"http://ad.madvertise.de";
  if(madDelegate != nil && [madDelegate respondsToSelector:@selector(adServer)]) {
    server_url = [madDelegate adServer];
  }
  MADLog(@"Using url: %@",server_url);
    
  // always supported request parameter //
  if (madDelegate == nil || ![madDelegate respondsToSelector:@selector(appId)]) {
    MADLog(@"delegate does not respond to appId ! return ...");
    return;
  }
  
  ////////////////  POST PARAMS ////////////////
  NSMutableDictionary* post_params = [[NSMutableDictionary alloc] init];
  self.receivedData = [NSMutableData data];
  
  NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/site/%@", server_url, [madDelegate appId]]];
  MADLog(@"AppId : %@",[madDelegate appId]);
  
  //get application name
  NSString *appName = [MadvertiseUtilities getAppName];
  [post_params setValue:appName forKey:@"app_name"];
  MADLog(@"application name: %@",appName);

  NSString *appVersion = [MadvertiseUtilities getAppVersion];
  [post_params setValue:appVersion forKey:@"app_version"];
  MADLog(@"application version: %@",appVersion);
  
  //get parent size
  CGSize parent_size =  [self getParentViewDimensions];
  [post_params setValue:[NSNumber numberWithFloat:parent_size.width] forKey:@"parent_width"];
  [post_params setValue:[NSNumber numberWithFloat:parent_size.height] forKey:@"parent_height"];
  MADLog(@"parent size: %.f x %.f",parent_size.width,parent_size.height);
  
  //get screen size
  CGSize screen_size = [self getScreenResolution];
  [post_params setValue:[NSNumber numberWithFloat:screen_size.width] forKey:@"device_width"];
  [post_params setValue:[NSNumber numberWithFloat:screen_size.height] forKey:@"device_height"];
  MADLog(@"screen size: %.f x %.f",screen_size.width,screen_size.height);
  
  //get screen orientation
  NSString* screen_orientation = [self getDeviceOrientation];
  [post_params setValue:screen_orientation forKey:@"orientation"];
  MADLog(@"screen orientation: %@",screen_orientation);
  
  
  // optional url request parameter
  if ([madDelegate respondsToSelector:@selector(location)]) {
    CLLocationCoordinate2D location = [madDelegate location];
    [post_params setValue:[NSString stringWithFormat:@"%.6f",location.longitude] forKey:@"lng"];
    [post_params setValue:[NSString stringWithFormat:@"%.6f",location.latitude] forKey:@"lat"];
  }
  
  if ([madDelegate respondsToSelector:@selector(gender)]) {
    NSString *gender = [madDelegate gender];
    [post_params setValue:gender forKey:@"gender"];
    MADLog(@"gender: %@",gender);
  }

  if ([madDelegate respondsToSelector:@selector(age)]) {
    NSString *age = [madDelegate age];
    [post_params setValue:age  forKey:@"age"];
    MADLog(@"%@",age);
  }
  
  MADLog(@"Init new request");
  self.request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0]; 
  
  NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];  
  [headers setValue:@"application/x-www-form-urlencoded; charset=utf-8" forKey:@"Content-Type"];  
  [headers setValue:@"application/vnd.madad+json; version=2" forKey:@"Accept"];

  
  UIDevice* device = [UIDevice currentDevice];
  
  NSString *ua = [MadvertiseUtilities buildUserAgent:device];
  MADLog(@"ua: %@", ua);
  
  // get IP
  NSString *ip = [MadvertiseUtilities getIP];
  MADLog(@"IP: %@", ip);

  NSString *hash = [MadvertiseUtilities base64Hash:[device uniqueIdentifier]];
  
  [post_params setValue:  @"true"         forKey:@"app"];
  [post_params setValue:  hash            forKey:@"uid"];
  [post_params setValue:  ua              forKey:@"ua"];
  [post_params setValue:  ip              forKey:@"ip"];
  [post_params setValue:  @"json"         forKey:@"format"];
  [post_params setValue:  @"iPhone-SDK "  forKey:@"requester"];
  [post_params setValue:  MADVERTISE_SDK_VERION forKey:@"version"];
  [post_params setValue:[MadvertiseUtilities getTimestamp] forKey:@"ts"];  
  [post_params setValue:MadvertiseAdClass_toString[currentAdClass] forKey:@"banner_type"];
  
  NSString *body = @"";  
  unsigned int n = 0;
  
  for( NSString* key in post_params) {
    body = [body stringByAppendingString:[NSString stringWithFormat:@"%@=%@", key, [post_params objectForKey:key]]];
    if(++n != [post_params count] ) 
      body = [body stringByAppendingString:@"&"];
  }
  
  [request setHTTPMethod:@"POST"];  
  [request setAllHTTPHeaderFields:headers];  
  [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
  MADLog(@"Sending request");
  
  self.conn = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
  MADLog(@"Request send");
  
  [headers release];
  [post_params release];
  [lock unlock];
}

- (void)openInSafariButtonPressed:(id)sender {
  MADLog(@"openInSafariButtonPressed called");
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:currentAd.clickUrl]];
}

- (void)openInAppBrowser {

  [self stopTimer];
  if ([madDelegate respondsToSelector:@selector(inAppBrowserWillOpen)]) {
    [madDelegate inAppBrowserWillOpen];
  }
  
  self.inAppLandingPageController = [[[InAppLandingPageController alloc] init] autorelease];
  inAppLandingPageController.onClose =  @selector(inAppBrowserClosed);
  inAppLandingPageController.ad = currentAd;
  inAppLandingPageController.banner_view = currentView;
  inAppLandingPageController.madvertise_view = self;

  // there isn't a rootViewController defined, try to find one
  if (!(self.rootViewController) && ([UIWindow instancesRespondToSelector:@selector(rootViewController)])) {
    self.rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
  }

  if (self.rootViewController) {
    inAppLandingPageController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    if (self.rootViewController.modalViewController) {
      [self.rootViewController.modalViewController presentModalViewController:inAppLandingPageController animated:YES];
    }
    else {
      [self.rootViewController presentModalViewController:inAppLandingPageController animated:YES];
    }
  }
  else {
    [inAppLandingPageController.view setFrame:[[UIScreen mainScreen] applicationFrame]];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:window cache:YES];
    
    [window addSubview:inAppLandingPageController.view];
    [UIView commitAnimations];
  }  
}

- (void)stopTimer {
  if (self.timer && [timer isValid]) {
    [self.timer invalidate];
    self.timer = nil;
  }
}

- (void)createAdReloadTimer {
  // prepare automatic refresh
  MADLog(@"Init Ad reload timer");
  [self stopTimer];
  self.timer = [NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(timerFired:) userInfo: nil repeats: YES];
}

- (void)inAppBrowserClosed {
  if ([madDelegate respondsToSelector:@selector(inAppBrowserClosed)]) {
    [madDelegate inAppBrowserClosed];
  }
  [self createAdReloadTimer];
}


// ad has been touched, open click_url from he current app according to click_action
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  MADLog(@"touchesBegan");
  if (currentAd.shouldOpenInAppBrowser)
    [self openInAppBrowser];
  else
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:currentAd.clickUrl]];
}  

// Refreshing the ad
- (void)timerFired: (NSTimer *) theTimer {
  if (madDelegate != nil && [madDelegate respondsToSelector:@selector(appId)]) {
    MADLog(@"Ad reloading");
    [self loadAd];
  }
}


- (void)destroyView:(UIView*) inView {
  if(inView != nil) {
    if ([inView isKindOfClass:[UIWebView class]]) {
      ((UIWebView*)inView).delegate = nil;
      [((UIWebView*)inView) stopLoading];
    }
    [inView removeFromSuperview];
  }
}


- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
  
  MadvertiseAnimationClass animationTyp;
  if ([madDelegate respondsToSelector:@selector(bannerAnimationTyp)]) {
    animationTyp = [madDelegate bannerAnimationTyp];
  }
  
  placeholder_1.alpha = 1.0;
  placeholder_2.alpha = 1.0;  

  switch (animationTyp) {
    case leftToRight:
      [self swapViewFormLeftToRight];
      break;
    case topToBottom:
      [self swapViewFormTopToBottom];
      break;
    case curlDown:
      [self swapViewWithCurlDownAnimation:aWebView];
    case none:
      [self swapViewWithoutAnimation:aWebView];
      break;
    case fade:
      [self swapViewWithFading];
      break;
    default:
      [self swapViewWithCurlDownAnimation:aWebView];
      break;
  }
}

- (void) displayView {
  MADLog(@"Display view");
  [self setUserInteractionEnabled:YES];
  
  if (currentAd == nil) {
    MADLog(@"No ad to show");
    [self setUserInteractionEnabled:NO];
    return;
  }
  
  self.frame = CGRectMake(x, y , currentAd.width, currentAd.height);
    
  if (currentAd.hasBanner) {
    if(visibleHolder == 0 || visibleHolder == 2){
      [placeholder_1 stopLoading];
      [placeholder_1 setFrame:CGRectMake(0, 0, currentAd.width, currentAd.height)];
      [placeholder_1 loadHTMLString:[currentAd to_html] baseURL:nil];
    }else{
      [placeholder_2 stopLoading];
      [placeholder_2 setFrame:CGRectMake(0, 0, currentAd.width, currentAd.height)];
      [placeholder_2 loadHTMLString:[currentAd to_html] baseURL:nil];
    }
    MADLog(@"htmlContent: %@",[currentAd to_html]);
    
  }else{
    
    // text ad
    //--------
    MADLog(@"Showing text ad");
    MadvertiseTextAdView* view = [MadvertiseTextAdView withText:currentAd.text];
    if(!currentView){
      self.currentView = view;
    }
    [view setFrame:self.frame];
  }
  //
  [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoaded" object:[NSNumber numberWithInt:responseCode]];
}


//////////////////////////////////////////
// private methonds for internal use only
//////////////////////////////////////////
#pragma mark - private methods section
- (CGSize) getParentViewDimensions{
  
  if([self superview] != nil){
    UIView *parent = [self superview];
    return CGSizeMake(parent.frame.size.width, parent.frame.size.height);
  }
  return CGSizeMake(0, 0);
}

- (CGSize) getScreenResolution{
  CGRect screen     = [[UIScreen mainScreen] bounds];
  return CGSizeMake(screen.size.width, screen.size.height);
}

- (NSString*) getDeviceOrientation{
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  if(UIDeviceOrientationIsLandscape(orientation)){
    return @"landscape";
  }else{
    return @"protrait";
  }
}


/////////////
//Animations
/////////////
#pragma mark - banner animation handling

- (void)swapViewWithCurlDownAnimation:(UIView*)view {
  [UIView beginAnimations:nil context:NULL];  
  [UIView setAnimationDuration:animationDuration];  
  [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self cache:YES];  
  [UIView setAnimationDelegate:self];
  [self addSubview:view];
  [UIView commitAnimations];  
}

- (void) swapViewFormLeftToRight{
  
  if(visibleHolder == 0){
    [self addSubview:placeholder_1];
    visibleHolder = 1;
  }else{
    CGRect frame1 = (visibleHolder==1)?placeholder_1.frame:placeholder_2.frame;
    CGRect frame2 = (visibleHolder==1)?placeholder_2.frame:placeholder_1.frame;
  
    frame1.origin.x = x;
    frame1.origin.x += frame1.size.width;
  
    frame2.origin.x = x;
    frame2.origin.x -= frame2.size.width;
  
    if(visibleHolder == 1){
      [placeholder_2 setFrame:frame2];
    }else{
      [placeholder_1 setFrame:frame2];
    }
  
    frame2.origin.x += frame2.size.width;
  
    if(visibleHolder == 1){
      [self addSubview:placeholder_2];
    }else{
      [self addSubview:placeholder_1];
    }
  
    [UIView beginAnimations:nil context:NULL];  
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];  
    [UIView setAnimationDuration:animationDuration];
  
    if(visibleHolder == 1){
      [placeholder_1 setFrame:frame1];
      [placeholder_2 setFrame:frame2];
    }else{
      [placeholder_1 setFrame:frame2];
      [placeholder_2 setFrame:frame1];
    }
  
    [UIView commitAnimations];
    visibleHolder = (visibleHolder == 1)?2:1;
  }
}


- (void) swapViewFormTopToBottom{
  
  if(visibleHolder == 0){
    [self addSubview:placeholder_1];
    visibleHolder = 1;
  }else{
    
    CGRect frame1 = (visibleHolder == 1) ? placeholder_1.frame : placeholder_2.frame;
    CGRect frame2 = (visibleHolder == 2) ? placeholder_2.frame : placeholder_1.frame;
    
    frame1.origin.y += frame1.size.height;
    frame2.origin.y -= frame2.size.height;
    
    if(visibleHolder == 1){
      [placeholder_2 setFrame:frame2];
      if([placeholder_2 superview] == nil){
        [self addSubview:placeholder_2];
      }
    }else{
      [placeholder_1 setFrame:frame2];
      if([placeholder_1 superview] == nil){
        [self addSubview:placeholder_1];
      }
    }
    
    frame2.origin.y += frame2.size.height;
    
    [UIView beginAnimations:nil context:NULL];  
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];  
    [UIView setAnimationDuration:animationDuration];
    
    if(visibleHolder == 1){
      [placeholder_1 setFrame:frame1];
      [placeholder_2 setFrame:frame2];
    }else{
      [placeholder_2 setFrame:frame1];
      [placeholder_1 setFrame:frame2];
    }
    
    [UIView commitAnimations];
    visibleHolder = (visibleHolder == 1)?2:1;
    
  }
  
}


- (void) swapViewWithFading{

  if(visibleHolder == 0){
    [self addSubview:placeholder_1];
    visibleHolder  = 1;
  }else{
    
    UIWebView *visibleView    = (visibleHolder == 1)?placeholder_1 : placeholder_2;
    CGRect frame1             = visibleView.frame;
    visibleView.alpha         = 1.0;
    if([visibleView superview] == nil){
      [self addSubview:visibleView]; 
    }
    
    [self bringSubviewToFront:visibleView];
        
    UIWebView *backgroundView = (visibleHolder == 1)?placeholder_2 : placeholder_1;
    backgroundView.alpha      = 0.0;
       
    [backgroundView setFrame:frame1];
    if([backgroundView superview] == nil){
      [self addSubview:backgroundView];   
    }
    
    [UIView beginAnimations:nil context:NULL];  
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];  
    [UIView setAnimationDuration:animationDuration];
      
    visibleView.alpha     = 0.0;
    backgroundView.alpha  = 1.0;
    
    [UIView commitAnimations];

    visibleHolder = (visibleHolder == 1)?2:1;
  }

}


- (void) swapViewWithoutAnimation:(UIView*)aWebView{
  
  if(visibleHolder == 0){
    [self addSubview:placeholder_1];
    visibleHolder  = 1;
  }else{

    if(visibleHolder == 1){
      [placeholder_2 setFrame:placeholder_1.frame];
      visibleHolder = 2;
    }else{
      [placeholder_1 setFrame:placeholder_2.frame];
      visibleHolder = 1;
    }	
  }
}

- (void) resetAnimation{
  visibleHolder = 0;
}

@end
