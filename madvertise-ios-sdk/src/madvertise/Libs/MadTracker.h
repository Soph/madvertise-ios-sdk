//
//  MadTracker.h
//  MadvertiseTracking
//
//  madvertise Download Tracker 4.0.1
//
//  Copyright 2010 madvertise Mobile Advertising GmbH . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface MadTracker : NSObject {
	
}

// sends a request on first start to the madvertise server
// !!call setDebugMode and setProductToken before!!
+ (void) reportAppLaunchedToMadvertise;

// set debug mode, default is NO
+ (void) setDebugMode: (BOOL) debugMode;

// set product token, that you will geth from madvertise
+ (void) setProductToken: (NSString *) productToken;

@end
