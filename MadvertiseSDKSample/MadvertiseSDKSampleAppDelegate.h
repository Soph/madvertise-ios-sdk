//
//  MadvertiseSDKSampleAppDelegate.h
//  MadvertiseSDKSample
//
//  Created by Nicolai Dymosz on 16.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnotherSDKTestViewController.h"

@interface MadvertiseSDKSampleAppDelegate : NSObject <UIApplicationDelegate> 
{
  AnotherSDKTestViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) AnotherSDKTestViewController *viewController;
@end
