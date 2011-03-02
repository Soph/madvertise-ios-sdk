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


#import <CoreLocation/CoreLocation.h>

@class MadvertiseView;

@protocol MadvertiseDelegationProtocol<NSObject>

// The appId is your token which associates this application with your site in the
// madvertise plattform. Log in under http://www.madvertise.de to get your appId.
- (NSString *) appId;


@optional 

// This is a callback if an ad has successfully been loaded. The MadvertiseView argument is a UIView 
// object which contains the ad.
- (void) adLoaded:(MadvertiseView*) view;

// This is a callback if no ad could be loaded.
- (void) adLoadFailed:(MadvertiseView*) view;

- (void) inAppBrowserWillOpen;

- (void) inAppBrowserClosed;

- (bool) debugEnabled;

// Implement this method to use another ad server (mainly for testing purpose).
// The default server is ad.madvertise.de.
- (NSString *) adServer;

//
// Below listed methods can be used to get a better targeting.
//


// Keywords separated by comma, e.g.
// - user's interests: @"sport,tennis,french open"
- (NSString *) query;


//
// Informatin about the device
//
- (CLLocation *)location;

//
// Information about the user
//
// @"female" or @"male"
- (NSString *) gender;

- (NSInteger *) age;

- (NSDate *) dateOfBirth;

// ISO 3166 country code, e.g. @"DE" for Germany, @"AT" for Austria, etc.
- (NSString *) countryCode;

// e.g. @"14129"
- (NSString *) zipCode;


@end
