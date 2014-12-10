//
//  W3wLanguageEnum.h
//  W3wSDK
//
//  Created by Mihai Dumitrache on 29/08/14.
//  Copyright (c) 2014 Work In Progress. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, kW3wLanguage) {
  kW3wLanguageEnglish,
  kW3wLanguageSwedish,
  kW3wLanguageRussian,
  kW3wLanguageSpanish,
  kW3wLanguageGerman,
  kW3wLanguagePortuguese,
  kW3wLanguageFrench,
  kW3wLanguageTurkish
};

@interface W3wLanguage : NSObject

+ (int)numberOfLanguages;

+ (NSLocale *)localeForLanguage:(kW3wLanguage)language;

+ (NSString *)nameForLanguage:(kW3wLanguage)language;

@end
