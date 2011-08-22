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

@class MadvertiseView;
@class MadvertiseAd;

@interface InAppLandingPageController : UIViewController <UIWebViewDelegate> {
  MadvertiseAd* ad;
  MadvertiseView* madvertise_view;
  UIView *banner_view;
  SEL onClose;
  UIView *banner_container;
  UIActivityIndicatorView *spinner;
  UIView *overlay;
  UIWebView* webview;
}

@property(nonatomic,retain) MadvertiseAd* ad;
@property(nonatomic,retain) MadvertiseView* madvertise_view;
@property(nonatomic,retain) UIView* banner_view;
@property(nonatomic,retain) UIView *banner_container;
@property(nonatomic,retain) UIActivityIndicatorView *spinner;
@property(nonatomic,retain) UIView *overlay;
@property(nonatomic,retain) UIWebView* webview;
@property SEL onClose;


@end
