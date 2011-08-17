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
#import "MadvertiseUtilities.h"


@implementation Ad

@synthesize bannerUrl;
@synthesize clickUrl;
@synthesize clickAction;
@synthesize text;
@synthesize hasBanner;
@synthesize width;
@synthesize height;
@synthesize shouldOpenInAppBrowser;

+(Ad*)initFromDictionary:(NSDictionary*)dictionary {
  
  Ad *ad = [Ad alloc];
  
  for (id key in dictionary) {
    [MadvertiseUtilities localDebug:[NSString stringWithFormat:@"%@=%@", key, [dictionary valueForKey:key]]];
  }
  
  ad.clickUrl     = [dictionary objectForKey:@"click_url"];
  ad.bannerUrl    = [dictionary objectForKey:@"banner_url"];  
  NSString *hasBanner = [dictionary objectForKey:@"has_banner"];
  ad.hasBanner    = hasBanner != nil ? [hasBanner boolValue] : NO;
  ad.text         = [dictionary objectForKey:@"text"];
  if(!ad.text)
    ad.text = @"";
  NSString *openInApp = [dictionary objectForKey:@"should_open_in_app"];
  ad.shouldOpenInAppBrowser = openInApp != nil ? [openInApp boolValue] : NO;
  
  ad.width  = 320;
  ad.height = 53;
  
  return ad;
}


-(NSString*)to_html {
  NSString* template = @""
  "<html>"
  "<head>"
  "<style type=\"text/css\"> body {margin-left:0px; margin-right:0px; margin-top:0px; margin-bottom:0px; padding:0px; background-color:black; text-align:center; border:none}</style>"
  "</head>"
  "<body>"
  "%@"
  "</body>"
  "</html>";

  NSString* body = @"HALLO!";

  if (self.bannerUrl) {
    body = [NSString stringWithFormat:@"<img src=\"%@\"></img>", self.bannerUrl];
  }
  
  return [NSString stringWithFormat:template, body];
}
@end
