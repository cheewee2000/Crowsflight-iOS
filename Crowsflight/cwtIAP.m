//
//  cwtInapp.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/27/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import "cwtIAP.h"

@implementation cwtIAP

+ (cwtIAP *)sharedInstance {
    static dispatch_once_t once;
    static cwtIAP * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      @"unlockcrowsflight",
                                    
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}





@end