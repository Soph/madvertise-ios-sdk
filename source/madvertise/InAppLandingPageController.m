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

#import "InAppLandingPageController.h"
#import <UIKit/UIBarButtonItem.h>
#import <QuartzCore/QuartzCore.h>
#import "MadvertiseView.h"
#import "MadvertiseAd.h"

@implementation InAppLandingPageController

@synthesize ad;
@synthesize banner_view;
@synthesize madvertise_view;
@synthesize onClose;
@synthesize banner_container;
@synthesize spinner;
@synthesize overlay;
@synthesize webview;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  
  UIView *view1 = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 460.0)];
  view1.backgroundColor = [UIColor colorWithWhite:1.000 alpha:1.000];
  view1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  view1.clearsContextBeforeDrawing = YES;
  view1.clipsToBounds = NO;
  view1.opaque = YES;
  view1.tag = 0;
  view1.userInteractionEnabled = YES;
  self.view = view1;
  [view1 release];
  
  UIWebView *view6 = [[UIWebView alloc] initWithFrame:CGRectMake(-20.0, -66.0, 340.0, 482.0)];
  view6.frame = CGRectMake(0.0, 0, 320.0, 460.0-44);
  view6.alpha = 1.000;
  view6.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  view6.clearsContextBeforeDrawing = YES;
  view6.clipsToBounds = YES;
  view6.contentMode = UIViewContentModeScaleToFill;
  view6.hidden = NO;
  view6.multipleTouchEnabled = YES;
  view6.opaque = YES;
  view6.scalesPageToFit = NO;
  view6.tag = 0;
  view6.userInteractionEnabled = YES;
  self.webview = view6;
  [view6 release];
  
  UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 416.0, 320.0, 44.0)];
  toolbar.frame = CGRectMake(0.0, 416.0, 320.0, 44.0);
  toolbar.alpha = 1.000;
  toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  toolbar.barStyle = UIBarStyleDefault;
  toolbar.clearsContextBeforeDrawing = NO;
  toolbar.clipsToBounds = NO;
  toolbar.contentMode = UIViewContentModeScaleToFill;
  toolbar.hidden = NO;
  toolbar.multipleTouchEnabled = NO;
  toolbar.opaque = NO;
  toolbar.tag = 0;
  toolbar.userInteractionEnabled = YES;
  
  UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back) ];
  [toolbar setItems:[NSArray arrayWithObjects:button, nil ]];
  [button release];
  
  [self.view addSubview:toolbar];
  [toolbar release];

  [self.view addSubview:self.webview];

  self.banner_container = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 210.0 - 44, 320.0, 52.0)] autorelease];
  [self.banner_container addSubview:self.banner_view];  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  CGRect rect = self.view.frame;
  
  self.overlay = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height - 44.0)] autorelease];
  self.overlay.alpha = 0.800;
  self.overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.overlay.backgroundColor = [UIColor colorWithRed:0.000 green:0.000 blue:0.000 alpha:1.000];
  [self.view addSubview:self.overlay];
  
  self.spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
  [spinner setCenter:CGPointMake(rect.size.width/2.0, (rect.size.height-20.0)/2.0 + 25.0)]; 
  self.spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
  [self.view addSubview:spinner]; // spinner is not visible until started
  [spinner startAnimating];
  
  self.webview.delegate = self;
  [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self.ad clickUrl]]]];  
}

bool gone = NO; 

- (void)back {
  if (self.parentViewController) {
    // this can only happen, when we were displayed as a modal view
    [self dismissModalViewControllerAnimated:YES];
  }
  else {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.0];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];  
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:window cache:YES];
    [self.view removeFromSuperview];
    [UIView commitAnimations];
  }
  [self.madvertise_view addSubview:self.banner_view];
  [self.madvertise_view performSelector:onClose];
  gone = NO;
}

-(void) afterFadeOut:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context  {
  [banner_container removeFromSuperview];
  [spinner stopAnimating];
  [spinner removeFromSuperview];
  [overlay removeFromSuperview];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  if(!gone) {
    [spinner stopAnimating];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(afterFadeOut:finished:context:)];
    [banner_container setAlpha:0];
    [spinner setAlpha:0];
    [overlay setAlpha:0];
    [UIView commitAnimations];
    gone = YES;
  }
}


- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  self.view = nil;
  self.overlay = nil;
  self.banner_container = nil;
  self.spinner = nil;
  self.webview.delegate = nil;
  self.webview = nil;
  self.overlay = nil;
  
  [super viewDidUnload];
}


- (void)dealloc {
  [self viewDidUnload];

  self.banner_view = nil;
  self.madvertise_view = nil;
  self.ad = nil;

  [super dealloc];
}

@end
