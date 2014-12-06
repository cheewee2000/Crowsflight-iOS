//
//  IAPHelper.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/27/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "cwtAppDelegate.h"


UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    cwtAppDelegate* dele;

}

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;

- (void)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;

- (void)restoreCompletedTransactions;

@end