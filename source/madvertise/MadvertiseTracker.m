//
//  MadTracker.m
//  MadvertiseTracking
//
//  Created by Moritz Becker on 11/1/10.
//  Copyright 2010 Madvertise. All rights reserved.
//

#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>
#import <netinet/in.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "MadvertiseUtilities.h"
#import "MadvertiseTracker.h"


// static variables
static BOOL madvertiseTrackerDebugMode = YES;

static BOOL trackerAlreadyEnabled = NO;

static NSString *productToken = @"test";
static NSString *madServer = @"http://ad.madvertise.de/action/";
//static NSString *madServer = @"http://127.0.0.1:9292/action/";

@implementation MadvertiseTracker


+ (void) enable {
  
  if(trackerAlreadyEnabled)
    return;
  trackerAlreadyEnabled = YES;
  
  [MadvertiseTracker reportActionToMadvertise:@"launch"];
  
  [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                    object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                                                      [MadvertiseTracker reportActionToMadvertise:@"active"];
                                                    }];

  [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                    object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                                                      [MadvertiseTracker reportActionToMadvertise:@"inactive"];
                                                    }];
  
  [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                    object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                                                      [MadvertiseTracker reportActionToMadvertise:@"stop"];
                                                    }];
  
  
  
}

+ (void) reportActionToMadvertise:(NSString*) action_type {
  [MadvertiseTracker performSelectorInBackground:@selector(report:) withObject:action_type];

}

+ (void) setDebugMode: (BOOL) debug {
	madvertiseTrackerDebugMode = debug;
}

+ (void) setProductToken: (NSString *) token {
	productToken = token;
}

+ (void) report: (NSString*) action_type {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
  MADLog(@"%@", documentsDirectory);
	
  NSString *appOpenPath = [documentsDirectory stringByAppendingPathComponent:@"mad_launch_tracking"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
  bool firstLaunch = ![fileManager fileExistsAtPath:appOpenPath];
	
  MADLog(@"Sending tracking request to madvertise. token=%@",productToken);
	
	UIDevice* device = [UIDevice currentDevice];
	NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", madServer , productToken]];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
	NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];  
	[headers setValue:@"application/x-www-form-urlencoded; charset=utf-8" forKey:@"Content-Type"];
	
	// set request parameter
	NSMutableDictionary* post_params = [[NSMutableDictionary alloc] init];
	[post_params setValue:[MadvertiseUtilities buildUserAgent:device] forKey:@"ua"];
	[post_params setValue:[MadvertiseUtilities getIP] forKey:@"ip"];
  [post_params setValue:[MadvertiseUtilities base64Hash:[device uniqueIdentifier]] forKey:@"uid"];
  [post_params setValue:[MadvertiseUtilities getTimestamp] forKey:@"ts"];  
  [post_params setValue:action_type forKey:@"at"];  
  [post_params setValue:(firstLaunch ? @"1" : @"0") forKey:@"first_launch"];  
  [post_params setValue:[MadvertiseUtilities getAppName] forKey:@"app_name"];
  [post_params setValue:[MadvertiseUtilities getAppVersion] forKey:@"app_version"];
	
	if (madvertiseTrackerDebugMode)
		[post_params setValue:@"true" forKey:@"debug"]; 
	
  NSString *body = @"";	
	unsigned int n = 0;
	for(NSString *key in post_params) {
		body = [body stringByAppendingString:[NSString stringWithFormat:@"%@=%@", key, [post_params objectForKey:key]]];
		if(++n != [post_params count]) 
			body = [body stringByAppendingString:@"&"];
	}
  
  [post_params release];
	
  [request setHTTPMethod:@"POST"];  
	[request setAllHTTPHeaderFields:headers]; 
	[request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLResponse *response = nil;
	NSError *error  = nil;
	
  NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if( (!error) && ([(NSHTTPURLResponse *)response statusCode] == 200)) {
		[fileManager createFileAtPath:appOpenPath contents:nil attributes:nil];
	}

#ifdef DEBUG
	NSString* debugMessage = [[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding];
  MADLog(@"Response from madvertise %@", debugMessage);
  [debugMessage release];
#endif 
  
  [headers release];
}

@end