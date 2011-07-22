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

////////////////////////////////////
/// Enum of available banner formats
////////////////////////////////////
typedef enum {
  exact, city, country 
} MadvertisePrecision;



@interface MadLocation : NSObject {
  float _lat;
  float _lng;
  MadvertisePrecision _precision;
}

@property (nonatomic,assign) float latiude;
@property (nonatomic,assign) float longtiude;
@property (nonatomic,assign) MadvertisePrecision precision;

- (id) initWithLatiude:(float)lat andLongitude:(float) lng andPrecision:(MadvertisePrecision) precision;

@end
