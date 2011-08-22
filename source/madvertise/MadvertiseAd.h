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

#import <Foundation/Foundation.h>

@interface MadvertiseAd : NSObject {
  NSString* clickUrl;
  NSString* clickAction;
  NSString* bannerUrl;
  NSString* text;
  bool hasBanner;
  bool shouldOpenInAppBrowser;
  int width;
  int height;
}

@property(nonatomic,retain) NSString *clickUrl;
@property(nonatomic,retain) NSString *clickAction;
@property(nonatomic,retain) NSString *bannerUrl;
@property(nonatomic,retain) NSString *text;

@property bool hasBanner;
@property bool shouldOpenInAppBrowser;
@property int height;
@property int width;


-(MadvertiseAd*)initFromDictionary:(NSDictionary*) dictionary;

-(NSString*)to_html;

@end
