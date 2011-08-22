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
#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>
#import <netinet/in.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIDevice.h>

#if DEBUG
#define MADLog(format, ...) [MadvertiseUtilities logWithPath:__FILE__ line:__LINE__ string:(format), ## __VA_ARGS__]
#else
#define MADLog(format, ...)
#endif

@interface MadvertiseUtilities : NSObject
+ (NSString *) getIP;
+ (NSString *) base64Hash:(NSString*) toHash;
+ (NSString *) buildUserAgent:(UIDevice*) device;
+ (NSString *) getTimestamp;
+ (NSString*) getAppName;
+ (NSString*) getAppVersion;
+ (void)logWithPath:(char *)path line:(NSUInteger)line string:(NSString *)format, ...;

@end
