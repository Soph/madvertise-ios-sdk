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

#import "MadvertiseTextAdView.h"


@interface MadvertiseTextAdView ()
- (id)initWithText:(NSString*) _text;
- (void)drawRect:(CGRect)rect;
@end

@implementation MadvertiseTextAdView

+ (MadvertiseTextAdView*)withText:(NSString*) text {
  return [[[MadvertiseTextAdView alloc] initWithText:text] autorelease];
}


- (id)initWithText:(NSString*)_text {
  if((self = [self initWithFrame: CGRectMake(0, 0, 320, 53)])) {
    // text 
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 53)];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.adjustsFontSizeToFitWidth = true;
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:30];
    label.text = _text;
    
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(235, 34, 100, 20)];
    label2.textColor = [UIColor whiteColor];
    label2.backgroundColor = [UIColor clearColor];
    label2.textAlignment = UITextAlignmentCenter;
    label2.font = [UIFont systemFontOfSize:9];
    label2.text = @"ad by madvertise";
    
    [self addSubview:label];
    [self addSubview:label2];
    
    [label release];
    [label2 release]; 

  }
  return self;
}


// draw background (color), in case a text is shown
- (void)drawRect:(CGRect)rect {
  CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
  CGGradientRef glossGradient;
  CGColorSpaceRef rgbColorspace;
  size_t num_locations = 2;
  CGFloat locations[2] = { 0.0, 1.0 };
  CGFloat components[8] = { 1.0, 1.0, 1.0, 0.35,  // Start color
                1.0, 1.0, 1.0, 0.06 }; // End color
  
  rgbColorspace = CGColorSpaceCreateDeviceRGB();
  glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
    
  CGRect currentBounds = self.bounds;
  CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
  CGPoint midCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMidY(currentBounds));
  CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, midCenter, 0);
    
  CGGradientRelease(glossGradient);
  CGColorSpaceRelease(rgbColorspace); 
}

@end
