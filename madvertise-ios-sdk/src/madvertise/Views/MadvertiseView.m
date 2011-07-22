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


#import "Ad.h"
#import "MadDebug.h"
#import <ifaddrs.h>
#import <sys/types.h>
#import "TextAdView.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import "MadTracker.h"
#import "MadLocation.h"
#import "MadvertiseView.h"
#import "CJSONDeserializer.h"
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>
#import "InAppLandingPageController.h"
#import "MadAdWhirlProtocol.h"
#import "AdWhirlView.h"


//////////////////////////////
//// SOME PRIVATE METHODS ////
//////////////////////////////

@interface MadvertiseView ()
- (NSString*) getAppName;
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
- (NSString*)getIP;
- (void) displayView;
- (void) stopTimer;
- (void)loadAd;       // load a new ad into an existing MadvertiseView 
                      // Ads should not be cached, nor should you request more than one ad per minute
@end


@implementation MadvertiseView

/////////////
// METHODS //
/////////////

- (void) dealloc {
  [MadDebug localDebug:@"Call dealloc in MadvertiseView"];
  [conn release];
  [post_params release];
  [self destroyView:currentView];
  
  if (timer != nil){
    [timer invalidate];
    [timer release];
    timer = nil;
  }
  
  if(inAppLandingPageController != nil){
    [inAppLandingPageController release];
    inAppLandingPageController = nil;
  }
  
  [madDelegate release];
  madDelegate = nil;

  [placeholder_1 release];
  [placeholder_2 release];
  [currentAd release];
  [lock release];
  
  currentView = nil;
  currentAd   = nil;
  lock        = nil;
  
    
  [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationDidBecomeActiveNotification object:nil];
  

  [super dealloc];
}

//////////////////////
// main-constructor //
//////////////////////

+ (MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh {
  
  // Download-Tracker
  //-----------------
  if([delegate respondsToSelector:@selector(downloadTrackerEnabled)]){
    if([delegate downloadTrackerEnabled] == YES){
      [MadTracker setDebugMode: NO];
      [MadTracker setProductToken:[delegate appId]];
      [MadTracker reportAppLaunchedToMadvertise];
    }
  }
  
  MadvertiseView *mv;
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
  mv = [[MadvertiseView alloc] initWithDelegate:delegate withClass:adClassValue secondsToRefresh:secondsToRefresh];
  [pool release];
  return [mv autorelease];
}

+ (void) adLoadedHandlerWithObserver:(id) observer AndSelector:(SEL) selector{
  [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"MadvertiseAdLoaded" object:nil];
}

+ (void) adLoadFailedHandlerWithObserver:(id) observer AndSelector:(SEL) selector{
  [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:@"MadvertiseAdLoadFailed" object:nil];
}

- (void)removeFromSuperview {
  [timer invalidate];
  [placeholder_1 removeFromSuperview];
  [placeholder_2 removeFromSuperview];
}

- (void)place_at_x:(int)x_pos y:(int)y_pos {
 
  x = x_pos;
  y = y_pos;
  
  if(currentAdClass == IABAd) {
    self.frame = CGRectMake(x_pos, y_pos, 320, 267);
  } else if(currentAdClass == MMAAd) {
    self.frame = CGRectMake(x_pos, y_pos, 320, 53);
  } else if(currentAdClass == leaderboard){
    self.frame = CGRectMake(x_pos, y_pos, 728, 90);
  } else if(currentAdClass == full_screen){
    self.frame = CGRectMake(x_pos, y_pos, 768, 768);
  } else if(currentAdClass == portrait){
    self.frame = CGRectMake(x_pos, y_pos, 766, 66);
  } else if(currentAdClass == landscape){
    self.frame = CGRectMake(x_pos, y_pos, 1024, 66);
  }
}

// helper method for initialization
- (MadvertiseView*)initWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh {
  
  [super init];
  
  self.clipsToBounds = YES; 
   
  currentAdClass     = adClassValue;
   
  [MadDebug localDebug:@"*** madvertise SDK 4.0.4 ***"];
  
  interval            = secondsToRefresh;
  request             = nil;
  receivedData        = nil;
  responseCode        = 200;
  isBannerMode        = true;
  
  // prepare automatic refresh
  [MadDebug localDebug:@"Init Timer"];
  
  if([delegate isKindOfClass:[NSObject class]] && [delegate respondsToSelector:@selector(setSelector:)] && [delegate respondsToSelector:@selector(setSelectorTarget:)]){
    [delegate performSelector:@selector(setSelector:) withObject:@selector(loadAd)];
    [delegate performSelector:@selector(setSelectorTarget:) withObject:self];
    [AdWhirlView requestAdWhirlViewWithDelegate:delegate];
  
  }else{
    [self createAdReloadTimer];
    
  }
  madDelegate  = delegate;
  [madDelegate retain];

  // load first ad
  lock = [[NSLock alloc] init];
  [self loadAd];
  
  placeholder_1 = [[UIWebView alloc] initWithFrame:CGRectZero];
  [placeholder_1 setUserInteractionEnabled:false];  
  placeholder_1.delegate = self;
  
  placeholder_2 = [[UIWebView alloc] initWithFrame:CGRectZero];
  [placeholder_2 setUserInteractionEnabled:false];  
  placeholder_2.delegate = self;
  
  visibleHolder     = 0;
  animationDuration = 0.75;
  
  if([madDelegate respondsToSelector:@selector(durationOfBannerAnimation)]){
    animationDuration = [madDelegate durationOfBannerAnimation];
  }
  
  //Notification
  //------------
  [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(stopTimer) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(createAdReloadTimer) name:UIApplicationDidBecomeActiveNotification object:nil];
  
  return self;
}


#pragma mark - server connection handling

// check, if response is OK
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
  [MadDebug localDebug:[NSString stringWithFormat:@"%@ %i", @"Received response code: ", [response statusCode]]];
  responseCode = [response statusCode];
  [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [MadDebug localDebug:@"Received data from Ad Server"];
  [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [MadDebug localDebug:@"Failed to receive ad"];
  [MadDebug localDebug:[error description]];
  
  // dispatch status notification
  //-----------------------------
  [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoadFailed" object:[NSNumber numberWithInt:responseCode]];

  [connection release];
  connection = nil;
  request    = nil;
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
  return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  
  if( responseCode == 200) {
    
    // parse response
    //---------------
    [MadDebug localDebug:@"Deserializing JSON"];
    NSString* jsonString = [[NSString alloc] initWithData:receivedData encoding: NSUTF8StringEncoding];
    [MadDebug localDebug:[NSString stringWithFormat:@"%@%@", @"Received string: ", jsonString]];
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    [jsonString release];
    
    NSDictionary *dictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    
    [MadDebug localDebug:@"Creating ad"];
    
    // create ad (and release old Ad)
    if(currentAd)
      [currentAd release];
    
    currentAd = [[Ad initFromDictionary:dictionary] retain];
    
    ////////////////////
    // banner formats //
    ////////////////////
    
    if(currentAdClass == IABAd) {
      currentAd.width   = 320;
      currentAd.height  = 267;
    } else if(currentAdClass == MMAAd) {
      currentAd.width   = 320;
      currentAd.height  = 53; 
    } else if(currentAdClass == leaderboard){
      currentAd.width   = 728;
      currentAd.height  = 90;
    } else if(currentAdClass == full_screen){
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
    //-----------------------------
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MadvertiseAdLoadFailed" object:[NSNumber numberWithInt:responseCode]];
  }
  
  [connection release];
  connection    = nil;
  request       = nil;
  [receivedData release];
  receivedData  = nil;
}

static char base64EncodingTable[64] = {
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
  'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
  'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};


- (NSString *) base64StringFromData: (NSData *)data length: (int)length {
  unsigned long ixtext, lentext;
  long ctremaining;
  unsigned char input[3], output[4];
  short i, charsonline = 0, ctcopy;
  const unsigned char *raw;
  NSMutableString *result;
  
  lentext = [data length]; 
  if (lentext < 1){
    return @"";
  }
  
  result = [NSMutableString stringWithCapacity: lentext];
  raw = [data bytes];
  ixtext = 0; 
  
  while (true) {
    ctremaining = lentext - ixtext;
    
    if (ctremaining <= 0) 
      break;        
    
    for (i = 0; i < 3; i++) { 
      unsigned long ix = ixtext + i;
      if (ix < lentext)
        input[i] = raw[ix];
      else
        input[i] = 0;
    }
    output[0] = (input[0] & 0xFC) >> 2;
    output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4);
    output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6);
    output[3] = input[2] & 0x3F;
    ctcopy = 4;
    switch (ctremaining) {
      case 1: 
        ctcopy = 2; 
        break;
      case 2: 
        ctcopy = 3; 
        break;
    }
    
    for (i = 0; i < ctcopy; i++){
      [result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];
    }
    
    for (i = ctcopy; i < 4; i++){
      [result appendString: @"="];
    }
    
    ixtext += 3;
    charsonline += 4;
    
    if ((length > 0) && (charsonline >= length))
      charsonline = 0;
  }
  return result;
}

// generate request, that is send to the ad server
- (void)loadAd {
  
  [lock lock];
  
  ////////////////  POST PARAMS ////////////////
  post_params = [[NSMutableDictionary alloc] init];
  
  if(request){
    [MadDebug localDebug:@"loadAd - returning because another request is running"];
    [lock unlock];
    return;
  }
  
  receivedData = [[NSMutableData data] retain];
  
  NSString *server_url = @"http://ad.madvertise.de";
  if(madDelegate != nil && [madDelegate respondsToSelector:@selector(adServer)]) {
    server_url = [madDelegate adServer];
  }
  [MadDebug localDebug:[NSString stringWithFormat:@"%@%@", @"Using url: ",server_url]];
  
  
  ////////////////////////////////////////
  // always supported request parameter //
  ////////////////////////////////////////
  
  //get application name
  //--------------------
  NSString *appName = [self getAppName];
  [post_params setValue:appName forKey:@"app_name"];
  [MadDebug localDebug:[NSString stringWithFormat:@"application name: %@",appName]];
  
  //get parent size
  //---------------
  CGSize parent_size =  [self getParentViewDimensions];
  [post_params setValue:[NSNumber numberWithFloat:parent_size.width] forKey:@"parent_width"];
  [post_params setValue:[NSNumber numberWithFloat:parent_size.height] forKey:@"parent_height"];
  [MadDebug localDebug:[NSString stringWithFormat:@"parent size: %.f x %.f",parent_size.width,parent_size.height,nil]];
  
  //get screen size
  //---------------
  CGSize screen_size = [self getScreenResolution];
  [post_params setValue:[NSNumber numberWithFloat:screen_size.width] forKey:@"device_width"];
  [post_params setValue:[NSNumber numberWithFloat:screen_size.height] forKey:@"device_height"];
  [MadDebug localDebug:[NSString stringWithFormat:@"screen size: %.f x %.f",screen_size.width,screen_size.height,nil]];
  
  //get screen orientation
  //----------------------
  NSString* screen_orientation = [self getDeviceOrientation];
  [post_params setValue:screen_orientation forKey:@"orientation"];
  [MadDebug localDebug:[NSString stringWithFormat:@"screen orientation: %@",screen_orientation]];
  
  
  ////////////////////////////////////
  // optional url request parameter //
  ////////////////////////////////////
  
  MadLocation *location = nil;
  if ([madDelegate respondsToSelector:@selector(location)]) {
    location = [madDelegate location];
    
    if(location != nil){
      [post_params setValue:[NSString stringWithFormat:@"%.6f",location.longtiude] forKey:@"lng"];
      [post_params setValue:[NSString stringWithFormat:@"%.6f",location.latiude] forKey:@"lat"];
    
      NSString *precision = @"";
      switch(location.precision){
        case city:
          precision = @"city";
          break;
        case exact:
          precision = @"exact";
          break;
        case country:
          precision = @"country";
          break;
      }
      [post_params setValue:precision forKey:@"coordinates_precision"];
    }
  }
  
  NSString *gender = @"";
  if ([madDelegate respondsToSelector:@selector(gender)]) {
    gender = [madDelegate gender];
    [post_params setValue:gender forKey:@"gender"];
    [MadDebug localDebug:[NSString stringWithFormat:@"gender: %@",gender]];
  }
  
  NSString *age = @"";
  if ([madDelegate respondsToSelector:@selector(age)]) {
    [post_params setValue: [madDelegate age] forKey:@"age"];
    [MadDebug localDebug: age];
  }
  
  if (madDelegate == nil || ![madDelegate respondsToSelector:@selector(appId)]) {
    [MadDebug localDebug:@"delegate does not respond to appId ! return ..."];
    return;
  }
  
  NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/site/%@", server_url, [madDelegate appId]]];
  [MadDebug localDebug:[NSString stringWithFormat:@"%@%@", @"AppId : ",[madDelegate appId]]];
  
  [MadDebug localDebug:@"Init new request"];
  request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0]; 
  
  NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];  
  [headers setValue:@"application/x-www-form-urlencoded; charset=utf-8" forKey:@"Content-Type"];  
  
  UIDevice* device = [UIDevice currentDevice];
  NSString *ua = [NSString stringWithFormat:@"iPhone APP-UA - %@ - %@ - %@ - %@", [device systemName],[device systemVersion], [device model], [device localizedModel]];
  [MadDebug localDebug:[NSString stringWithFormat:@"%@%@", @"ua: ", ua]];
  
  // get IP
  NSString *ip = [self getIP];
  [MadDebug localDebug:[NSString stringWithFormat:@"%@%@", @"IP: ", ip]];
  
  // get UUID .. and SHA1 it
  // !! same code is used in the download tracker !!
  NSString *key       = @"madvertise";
  NSString *data      = [device uniqueIdentifier];
  const char *cKey    = [key cStringUsingEncoding:NSASCIIStringEncoding];
  const char *cData   = [data cStringUsingEncoding:NSASCIIStringEncoding];
  unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
  NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
  NSString *hash = [self base64StringFromData:HMAC length:[HMAC length]];
  
  [post_params setValue:  @"true"         forKey:@"app"];
  [post_params setValue:  hash            forKey:@"uid"];
  [post_params setValue:  ua              forKey:@"ua"];
  [post_params setValue:  ip              forKey:@"ip"];
  [post_params setValue:  @"json"         forKey:@"format"];
  [post_params setValue:  @"iPhone-SDK "  forKey:@"requester"];
  [post_params setValue:  @"4-0-4"        forKey:@"version"];
  
  NSString* banner_type;
  if(currentAdClass == IABAd) {
    banner_type = @"iab";
  } else if(currentAdClass == MMAAd) {
    banner_type = @"mma";
  } else if(currentAdClass == leaderboard){
    banner_type = @"leaderboard";
  } else if(currentAdClass == full_screen){
    banner_type = @"full_screen";
  } else if(currentAdClass == portrait){
    banner_type = @"portrait";
  } else if(currentAdClass == landscape){
    banner_type = @"landscape";
  } else if(currentAdClass == all){
    banner_type = @"all";
  }
  
  [post_params setValue:banner_type forKey:@"banner_type"];
  
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
  [MadDebug localDebug:@"Sending request"];
  
  conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  [MadDebug localDebug:@"Request send"];
  
  [headers release];
  [lock unlock];
}

- (void)openInSafariButtonPressed:(id)sender {
  [MadDebug localDebug:@"openInSafariButtonPressed called"];  
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:currentAd.clickUrl]];
}

- (void)openInAppBrowser {

  [self stopTimer];
  inAppLandingPageController = [[InAppLandingPageController alloc] init];  
  inAppLandingPageController.onClose =  @selector(inAppBrowserClosed);
  inAppLandingPageController.ad = currentAd;
  inAppLandingPageController.banner_view = currentView;
  inAppLandingPageController.madvertise_view = self;
  [inAppLandingPageController.view setFrame:[[UIScreen mainScreen] applicationFrame]];

  UIWindow *window = [[UIApplication sharedApplication] keyWindow];  
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:1.0];
  [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:window cache:YES];
  
  [window addSubview:inAppLandingPageController.view];
  [UIView commitAnimations];
}

- (void) stopTimer{
  [timer invalidate];
  [timer release];
  timer = nil;
}

- (void)createAdReloadTimer {
  if(timer != nil){
    [self stopTimer];
  }
  timer = [[NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(timerFired:) userInfo: nil repeats: YES] retain];
}

- (void)inAppBrowserClosed {
  [self createAdReloadTimer];
}


// ad has been touched, open click_url from he current app according to click_action
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [MadDebug localDebug:@"touchesBegan"];
  
  if([currentAd.adType isEqualToString:@"http"] && !currentAd.shouldOpenInSafari){
    [self openInAppBrowser];
  } else{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:currentAd.clickUrl]];
  }
}  

// Refreshing the ad
- (void) timerFired: (NSTimer *) theTimer {
  if (madDelegate != nil && [madDelegate respondsToSelector:@selector(appId)]) {
    [MadDebug localDebug:@"Ad reloading"];
    [self loadAd];
  }
}

// get the ip adress from the iphone / ipod
- (NSString*)getIP {
  
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSString *result = nil;
  
  struct ifaddrs*  addrs;
  BOOL success = (getifaddrs(&addrs) == 0);
  if (success)
  {
    const struct ifaddrs* cursor = addrs;
    while (cursor != NULL)
    {
      NSMutableString* ip;
      NSString* interface = nil;
      if (cursor->ifa_addr->sa_family == AF_INET)
      {
        const struct sockaddr_in* dlAddr = (const struct sockaddr_in*) cursor->ifa_addr;
        const uint8_t* base = (const uint8_t*)&dlAddr->sin_addr;
        ip = [[NSMutableString new] autorelease];
        for (int i = 0; i < 4; i++)
        {
          if (i != 0)
            [ip appendFormat:@"."];
          [ip appendFormat:@"%d", base[i]];
        }
        interface = [NSString stringWithFormat:@"%s", cursor->ifa_name];
        if([interface isEqualToString:@"en0"] && result == nil) {
          result = ip;
        }
        if(![interface isEqualToString:@"lo0"] && ![interface isEqualToString:@"en0"] && ![interface isEqualToString:@"fw0"] && ![interface isEqualToString:@"en1"] ) {
          [MadDebug localDebug: [NSString stringWithFormat:@"Interface: %@", interface ]];
          result = ip;
        }
      }
      cursor = cursor->ifa_next;
    }
    freeifaddrs(addrs);
  }
  [result retain];
  [pool release];
  if(result == nil)
    result = @"127.0.0.1";
  return result;
}


- (void)destroyView:(UIView*) inView {
  if(inView != nil) {
    if ([inView isKindOfClass:[UIWebView class]]) {
      ((UIWebView*)inView).delegate = nil;
      [((UIWebView*)inView) stopLoading];
    }
    [inView removeFromSuperview];
    [inView release];
  }
  
}


- (void) webViewDidFinishLoad:(UIWebView *)aWebView {
  
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
  [MadDebug localDebug:@"Display view"];
  [self setUserInteractionEnabled:true];
  
  if (currentAd == nil) {
    [MadDebug localDebug:@"No ad to show"];
    [self setUserInteractionEnabled:false];
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
    [MadDebug localDebug:[NSString stringWithFormat:@"htmlContent:",[currentAd to_html]]];
    
  }else{
    
    // text ad
    //--------
    [MadDebug localDebug:@"Showing text ad"];
    TextAdView* view = [TextAdView withText:currentAd.text];
    if(!currentView){
      currentView = view;
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

- (NSString*) getAppName{
  NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
  return appName;
}

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
    return @"portrait";
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

- (void)viewSwapFinished:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
  [self destroyView:oldView];
}

- (void) resetAnimation{
  visibleHolder = 0;
}

@end
