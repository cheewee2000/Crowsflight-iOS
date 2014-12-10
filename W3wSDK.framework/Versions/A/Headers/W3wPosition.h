//
//  W3wPosition.h
//  W3wSDK
//
//  Created by Mihai Dumitrache on 29/08/14.
//  Copyright (c) 2014 Work In Progress. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "W3wLanguage.h"

@interface W3wPosition : NSObject

@property (nonatomic, assign) int i;
@property (nonatomic, assign) int j;
@property (nonatomic, assign) int k;

@property (nonatomic, strong) NSString *word1;
@property (nonatomic, strong) NSString *word2;
@property (nonatomic, strong) NSString *word3;

@property (nonatomic, assign) double lat;
@property (nonatomic, assign) double lng;

@property (nonatomic, assign) double swLat;
@property (nonatomic, assign) double swLng;
@property (nonatomic, assign) double neLat;
@property (nonatomic, assign) double neLng;

@property (nonatomic, assign) kW3wLanguage lang;

- (instancetype)initWithLanguage:(kW3wLanguage)language;

- (void)setWords:(NSString *)word1 word2:(NSString *)word2 word3:(NSString *)word3;

- (void)setBounds:(double)swLat swLng:(double)swLng neLat:(double)neLat neLng:(double)neLng;

- (NSString *)getW3w;

- (BOOL)isSea;

@end
