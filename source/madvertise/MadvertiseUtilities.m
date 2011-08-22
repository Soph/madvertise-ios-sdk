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

#import <Foundation/NSData.h>
#import "MadvertiseUtilities.h"


@implementation MadvertiseUtilities


+ (NSString *) getIP {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSString *result = nil;
	
	struct ifaddrs*	addrs;
	BOOL success = (getifaddrs(&addrs) == 0);
	if (success)
	{
		const struct ifaddrs* cursor = addrs;
		while (cursor != NULL)
		{
			NSMutableString* ip;
			NSString* interface = nil;
			if (cursor->ifa_addr->sa_family == AF_INET)
			{
				const struct sockaddr_in* dlAddr = (const struct sockaddr_in*) cursor->ifa_addr;
				const uint8_t* base = (const uint8_t*)&dlAddr->sin_addr;
				ip = [[NSMutableString new] autorelease];
				for (int i = 0; i < 4; i++)
				{
					if (i != 0)
						[ip appendFormat:@"."];
					[ip appendFormat:@"%d", base[i]];
				}
				interface = [NSString stringWithFormat:@"%s", cursor->ifa_name];
				if([interface isEqualToString:@"en0"] && result == nil) {
					result = ip;
				}
				if(![interface isEqualToString:@"lo0"] && ![interface isEqualToString:@"en0"] && ![interface isEqualToString:@"fw0"] && ![interface isEqualToString:@"en1"] ) {
					// NSLog(@"Interface %@", interface);
					result = ip;
				}
			}
			cursor = cursor->ifa_next;
		}
		freeifaddrs(addrs);
	}
	[result retain];
	[pool release];
	if(result == nil)
		result = @"127.0.0.1";
	return result;
}

static char base64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

+ (NSString *) base64StringFromData: (NSData *) data {
  NSMutableString *dest = [NSMutableString stringWithString:@""]; 
  unsigned char * working = (unsigned char *)[data bytes];
  int srcLen = [data length];
    
  // tackle the source in 3's as conveniently 4 Base64 nibbles fit into 3 bytes
  for (int i=0; i<srcLen; i += 3)
  {
    // for each output nibble
    for (int nib=0; nib<4; nib++)
    {
      // nibble:nib from char:byt
      int byt = (nib == 0)?0:nib-1;
      int ix = (nib+1)*2;
        
      if (i+byt >= srcLen) break;
        
      // extract the top bits of the nibble, if valid
      unsigned char curr = ((working[i+byt] << (8-ix)) & 0x3F);
        
      // extract the bottom bits of the nibble, if valid
      if (i+nib < srcLen) curr |= ((working[i+nib] >> ix) & 0x3F);
        
      [dest appendFormat:@"%c", base64[curr]];
    }
      
  }
  for(int i = 0; i < [dest length] - (([dest length] / 4) * 4); i++)
    [dest appendString:@","];
  return dest;
}

+ (NSString *) base64Hash:(NSString*) toHash {
  const char *cKey  = [@"madvertise" cStringUsingEncoding:NSASCIIStringEncoding];
  const char *cData = [toHash cStringUsingEncoding:NSASCIIStringEncoding];
  unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
  NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
  NSString* result = [MadvertiseUtilities base64StringFromData:HMAC];
  [HMAC release];
  return result;
    
}

+ (NSString*) buildUserAgent:(UIDevice *)device {
  return [NSString stringWithFormat:@"iPhone APP-UA - %@ - %@ - %@ - %@", [device systemName],[device systemVersion], [device model], [device localizedModel]];
}

+ (NSString*) getTimestamp {
  return [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
}

+ (NSString*) getAppName {
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

+ (NSString*) getAppVersion {
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (void)logWithPath:(char *)path line:(NSUInteger)line string:(NSString *)format, ... {
	NSString *pathString = [[NSString alloc] initWithBytes:path	length:strlen(path) encoding:NSUTF8StringEncoding];
	
	va_list argList;
	va_start(argList, format);
	NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:argList];
	va_end(argList);
	
	NSLog(@"%@", [NSString stringWithFormat:@"%@ (%d): %@", [pathString lastPathComponent], line, formattedString]);
	[formattedString release];
	[pathString release];
}

@end
