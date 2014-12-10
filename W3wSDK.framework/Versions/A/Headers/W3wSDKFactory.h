//
//  W3wSDKFactory.h
//  W3wSDK
//
//  Created by Mihai Dumitrache on 29/08/14.
//  Copyright (c) 2014 Work In Progress. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "W3wLanguage.h"

@class W3wSDK;
@class W3wDataInputStream;

@interface W3wSDKFactory : NSObject

- (id)initWithMasterFilePath:(NSString *)masterFilePath
            yBucketsFilePath:(NSString *)yBucketsFilePath
         englishWordListPath:(NSString *)englishWordListPath;

- (void)addEnglish;

- (void)addLanguage:(kW3wLanguage)language
           wordList:(NSString *)wordListPath
         blockOrder:(NSString *)blockOrder;

- (W3wSDK *)build;

@end
