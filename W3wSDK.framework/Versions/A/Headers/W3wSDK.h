//
//  W3wSDK.h
//  W3wSDK
//
//  Created by Mihai Dumitrache on 29/08/14.
//  Copyright (c) 2014 Work In Progress. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "W3wLanguage.h"
#import "W3wSDKFactory.h"
#import "W3wPosition.h"

@class W3wPosition;
@class W3wLanguage;
@class W3wGlobalWordList;

@interface W3wSDK : NSObject

- (instancetype)initWithGlobalWordList:(W3wGlobalWordList *)globalWordList
                               dataMap:(NSDictionary *)attDataMap;

- (W3wPosition *)convertW3WToPosition:(NSArray *)w3w;
- (W3wPosition *)convertPositionToW3W:(kW3wLanguage)lang lat:(double)lat lng:(double)lng;

+ (NSString *)getVersion;

@end
