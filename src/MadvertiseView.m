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

#import "MadvertiseView.h"
#import "TextAdView.h"
#import "CJSONDeserializer.h"
#import "MadDebug.h"
#import "Ad.h"
#import "InAppLandingPageController.h"

#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>
#import <netinet/in.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation MadvertiseView


//////////
// METHODS
//////////


// constructor
+(MadvertiseView*)loadAdWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh {
  return [[MadvertiseView alloc] initWithDelegate:delegate withClass:adClassValue secondsToRefresh:secondsToRefresh];
}

//-(id)retain {
//  
//  return [super retain];
//  
//}
//
//-(oneway void)release {
//  
//  return [super release];
//  
//}

- (void)removeFromSuperview {
  [timer invalidate];
  [super removeFromSuperview];
}

-(void)place_at_x:(int)x_pos y:(int)y_pos {
  x = x_pos;
  y = y_pos;
  if(currentAdClass == MMAAd)
    self.frame = CGRectMake(x_pos, y_pos, 320, 53);
  else
    self.frame = CGRectMake(x_pos, y_pos, 320, 267);
}

// helper method for initialization
- (MadvertiseView*)initWithDelegate:(id<MadvertiseDelegationProtocol>)delegate withClass:(MadvertiseAdClass)adClassValue secondsToRefresh:(int)secondsToRefresh {
  [super init];
  madDelegate = delegate;
  [madDelegate retain]; 
  currentAdClass = adClassValue;
  bool enable_debug = false;
  if(madDelegate != nil && [madDelegate respondsToSelector:@selector(debugEnabled)]) {
    enable_debug = [madDelegate debugEnabled];
  }
  [MadDebug showOutput:enable_debug];
  
  [MadDebug localDebug:@"*** madvertise SDK 4.0.4 ***"];
  
  interval = 0;
  
  interval = secondsToRefresh;
  request = nil;
  receivedData = nil;
  
  // flag that indicates if http response from ad server is ok
  responseCodeOK = false;
  
  // flag that indicates if the view shows a banner or a popup
  isBannerMode = true;
  
  // prepare automatic refresh
  [MadDebug localDebug:@"Init Timer"];
  [self createAdReloadTimer];
  
  // load first ad
  lock = [[NSLock alloc] init];

  [self loadAd];
  
  return self;
}


// check, if response is OK
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
  [MadDebug localDebug:[NSString stringWithFormat:@"%@ %i", @"Received response code: ", [response statusCode]]];
  //NSLog(@"did receive response before : %d", [self retainCount]);
  if([response statusCode] == 200) {
    responseCodeOK = true;
  } else {
    responseCodeOK = false;
  }
  // reset received data!
  [receivedData setLength:0];
  //NSLog(@"did receive response after : %d", [self retainCount]);
}

// store received data to a local variable
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [MadDebug localDebug:@"Received data from Ad Server"];
  //NSLog(@"did receive data before : %d", [self retainCount]);
  [receivedData appendData:data];
  //NSLog(@"did receive data after : %d", [self retainCount]);
}

// error handling, call delegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [MadDebug localDebug:@"Failed to receive ad"];
  responseCodeOK = false;
  [MadDebug localDebug:[error description]];
  
  // check, if the delegate implements the method
  if(madDelegate != nil && [madDelegate respondsToSelector:@selector(adLoadFailed:)]) {
    [madDelegate adLoadFailed:self];
  }
  
    // release the connection, and the data object  
  [connection release];
  connection = nil;
  request = nil;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
  return nil;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  // NSLog(@"connection did finish loading before : %d", [self retainCount]);
  if( responseCodeOK ) {
    // parse response
    [MadDebug localDebug:@"Deserializing JSON"];
    NSString* jsonString = [[NSString alloc] initWithData:receivedData encoding: NSUTF8StringEncoding];
    [MadDebug localDebug:[NSString stringWithFormat:@"%@%@", @"Received string: ", jsonString]];
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary *dictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    
    [MadDebug localDebug:@"Creating ad"];
    
    // create ad (and release old Ad)
    if(currentAd)
      [currentAd release];
    
    currentAd = [Ad initFromDictionary:dictionary];
    
    // force size of banner
    if(currentAdClass == IABAd) {
      currentAd.width = 320;
      currentAd.height = 267;
    } else {
      currentAd.width = 320;
      currentAd.height = 53; 
    }
    [self displayView];
    
  } else {
    if(madDelegate != nil && [madDelegate respondsToSelector:@selector(adLoadFailed:)]) {
      [madDelegate adLoadFailed:self];
    }
  }
    // release the connection, and the data object  
  [connection release];
  connection = nil;
  request = nil;
    [receivedData release];
  receivedData = nil;
  //NSLog(@"connection did finish loading after : %d", [self retainCount]);
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
  if (lentext < 1)
    return @"";
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
    
    for (i = 0; i < ctcopy; i++)
      [result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]];
    
    for (i = ctcopy; i < 4; i++)
      [result appendString: @"="];
    
    ixtext += 3;
    charsonline += 4;
    
    if ((length > 0) && (charsonline >= length))
      charsonline = 0;
  }
  return result;
}

// generate request, that is send to the ad server
- (void)loadAd {
  // [MadDebug localDebug:[NSString stringWithFormat:@"%@%@ - %@ - %@", @"Lock is : ",lock,self,request]];
  [lock lock];
  if(request) {
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
  
  
  //NSString *query = @"";
  //if ([madDelegate respondsToSelector:@selector(query)]) {
  //  query = [madDelegate query];
  //}
  
  //CLLocation *location = [CLLocation new];
  //if ([madDelegate respondsToSelector:@selector(location)]) {
  //  location = [madDelegate location];
  //}
  
  //NSString *gender = @"";
  //if ([madDelegate respondsToSelector:@selector(gender)]) {
  //  gender = [madDelegate gender];
  //}
  
  //NSInteger *age = [NSInteger initWithInt:0];
  //if ([madDelegate respondsToSelector:@selector(age)]) {
  //  age = [madDelegate age];
  //}
  
  //NSDate *dateOfBirth = [NSDate dateWithTimeIntervalSince1970:[NSTimeInterval initWithInt:0]];
  //if ([madDelegate respondsToSelector:@selector(dateOfBirth)]) {
  //  dateOfBirth = [madDelegate dateOfBirth];
  //}
  
  //NSString *countryCode = @"";
  //if ([madDelegate respondsToSelector:@selector(countryCode)]) {
  //  countryCode = [madDelegate countryCode];
  //}
  
  //NSString *zipCode = @"";
  //if ([madDelegate respondsToSelector:@selector(zipCode)]) {
  //  zipCode = [madDelegate zipCode];
  //}
  
  if (madDelegate == nil || ![madDelegate respondsToSelector:@selector(appId)]) {
    [MadDebug localDebug:@"delegate does not respond to appId ! return ..."];
    return;
  }
  
  NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/site/%@", server_url, [madDelegate appId]]];
  [MadDebug localDebug:[NSString stringWithFormat:@"%@%@", @"AppId : ",[madDelegate appId]]];
  
  [MadDebug localDebug:@"Init new request"];
    request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0]; 
  // [MadDebug localDebug:[NSString stringWithFormat:@"%@%@", @"request instance: ",request]];

  
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
  NSString *key = @"madvertise";
  NSString *data = [device uniqueIdentifier];
  const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
  const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
  unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
  NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
  NSString *hash = [self base64StringFromData:HMAC length:[HMAC length]];
  
  NSMutableDictionary* post_params = [[NSMutableDictionary alloc] init];  
  [post_params setValue:@"true" forKey:@"app"];
  [post_params setValue:hash forKey:@"uid"];
  [post_params setValue:ua forKey:@"ua"];
  [post_params setValue:ip forKey:@"ip"];
  [post_params setValue:@"json" forKey:@"format"];
  [post_params setValue:@"iPhone-SDK" forKey:@"requester"];
  [post_params setValue:@"4-0-4" forKey:@"version"];
  
  NSString* banner_type;
  if(currentAdClass == IABAd) {
    banner_type = @"iab";
  } else {
    banner_type = @"mma";
  }
  
  [post_params setValue:banner_type forKey:@"banner_type"];
  
  //[post_params setValue:@"iphone_2" forKey:@"version"];
  //[post_params setValue:query forKey:@"query"];
  //[post_params setValue:location forKey:@"location"];
  //[post_params setValue:gender forKey:@"gender"];
  //[post_params setValue:age forKey:@"age"];
  //[post_params setValue:dateOfBirth forKey:@"dateOfBirth"];
  //[post_params setValue:countryCode forKey:@"countryCode"];
  //[post_params setValue:zipCode forKey:@"zipCode"];
  
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
  [[NSURLConnection alloc] initWithRequest:request delegate:self];
  [MadDebug localDebug:@"Request send"];
  [lock unlock];
}

- (void)openInSafariButtonPressed:(id)sender {
  [MadDebug localDebug:@"openInSafariButtonPressed called"];  
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:currentAd.clickUrl]];
}

- (void)openInAppBrowser {
  
  // stop timer!
  [timer invalidate];
  [timer release];
  
  inAppLandingPageController = [[InAppLandingPageController alloc] init];  
  inAppLandingPageController.onClose =  @selector(inAppBrowserClosed);
  inAppLandingPageController.ad = currentAd;
  inAppLandingPageController.banner_view = currentView;
  inAppLandingPageController.madvertise_view = self;
  [inAppLandingPageController.view setFrame:[[UIScreen mainScreen] applicationFrame]];
  //[controller.view setFrame:CGRectMake(0, 0, 320, 50)];

  UIWindow *window = [[UIApplication sharedApplication] keyWindow];  
  // [self addSubview:controller.view];
  // [self bringSubviewToFront:controller.view];
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:1.0];
  [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:window cache:YES];
  // [self addSubview:controller.view];
  [window addSubview:inAppLandingPageController.view];
  [UIView commitAnimations];
}

- (void)createAdReloadTimer {
  timer = nil;
  if (interval > 0 && interval < 30)
    interval = 30;
  if (interval > 29)
    timer = [[NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(timerFired:) userInfo: nil repeats: YES] retain];
}

- (void)inAppBrowserClosed {
  [self createAdReloadTimer];
}


// ad has been touched, open click_url from he current app according to click_action
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [MadDebug localDebug:@"touchesBegan"];
  
  if(currentAd.shouldOpenInSafari)
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:currentAd.clickUrl]];
  else if (currentAd.shouldOpenInAppBrowser)
    [self openInAppBrowser];
  
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

- (void)swapViewWithAnimation:(UIView*)view {
  [UIView beginAnimations:nil context:NULL];  
  [UIView setAnimationDuration:0.75];  
  [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self cache:YES];  
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(viewSwapFinished:finished:context:)];
  [self addSubview:view];
  [UIView commitAnimations];  
  if(view != currentView) {
    oldView = currentView;
    currentView = view;
  }
}

- (void)destroyView:(UIView*) inView {
  if(inView != nil) {
    //  [MadDebug localDebug:@"Removing current view"];
    if ([inView isKindOfClass:[UIWebView class]]) {
      ((UIWebView*)inView).delegate = nil;
      [((UIWebView*)inView) stopLoading];
    }
    
    [inView removeFromSuperview];
    [inView release];
  }
  
}


- (void)viewSwapFinished:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
  [self destroyView:oldView];
}
  

- (void) webViewDidFinishLoad:(UIWebView *)webView {
  [self swapViewWithAnimation: webView];
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
    UIWebView* view = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0 , currentAd.width, currentAd.height)];
    if(!currentView)
      currentView = view;
    [view setUserInteractionEnabled:false];  
    [MadDebug localDebug:[currentAd to_html]];
    //NSLog(@"display View before  : %d", [self retainCount]);
    view.delegate = self;
    [view loadHTMLString:[currentAd to_html] baseURL:nil];
    //NSLog(@"display View after : %d", [self retainCount]);
  } else {
    // text ad
    [MadDebug localDebug:@"Showing text ad"];
    TextAdView* view = [TextAdView withText:currentAd.text];
    if(!currentView)
      currentView = view;
    [view setFrame:self.frame];
    [self swapViewWithAnimation: view];
  }

  if(madDelegate != nil && [madDelegate respondsToSelector:@selector(adLoaded:)]) {
    [madDelegate adLoaded:self];
  }
}


- (void) dealloc {
  [MadDebug localDebug:@"Call dealloc in MadvertiseView"];

  [self destroyView:currentView];
  
  if (timer != nil) {
    [timer invalidate];
    [timer release];
    timer = nil;
  }
  
  if(inAppLandingPageController != nil) {
    [inAppLandingPageController release];
    inAppLandingPageController = nil;
    
  }
  
  [madDelegate release];
  madDelegate = nil;
  
  [currentAd release];
  [lock release];

  currentView = nil;
  currentAd = nil;
  lock = nil;

    [super dealloc];
}
@end
