//
//  IAPHelper.m
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/27/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

// 1
#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>

NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";

// 2
@interface IAPHelper () <SKProductsRequestDelegate>
@end

@implementation IAPHelper {
    // 3
    SKProductsRequest * _productsRequest;
    // 4
    RequestProductsCompletionHandler _completionHandler;
    NSSet * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
}

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    
    dele = [[UIApplication sharedApplication] delegate];

    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

    
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                NSLog(@"Previously purchased: %@", productIdentifier);
            } else {
                NSLog(@"Not purchased: %@", productIdentifier);
            }
        }
        
    }
    return self;
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    
    // 1
    _completionHandler = [completionHandler copy];
    
    // 2
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
    
    [dele.overlay show];
    if(dele.overlay.isShrinked==YES) [dele.overlay setShrinked:NO animated:YES ];
    [dele.overlay postImmediateMessage:@"loading in app purchase"  duration:0 ];


    
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSLog(@"Loaded list of products...");
    
    NSArray * skProducts = response.products;
    
    
//    for (SKProduct * skProduct in skProducts) {
//        NSLog(@"Found product: %@ %@ %0.2f",
//              skProduct.productIdentifier,
//              skProduct.localizedTitle,
//              skProduct.price.floatValue);
//    }
    
    if([skProducts count]>0){
        _completionHandler(YES, skProducts);
        _completionHandler = nil;
    }
    
    _productsRequest = nil;


}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"Failed to load list of products.");
    _productsRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
    
    [dele.overlay postImmediateErrorMessage:@"Failed to load store"  duration:5.0 animated:YES];

    
}

- (BOOL)productPurchased:(NSString *)productIdentifier {
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)buyProduct:(SKProduct *)product {
    
    NSLog(@"Buying %@...", product.productIdentifier);
        
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    //[dele.overlay postImmediateMessage:@"Completing Transaction"  duration:5.0 ];

    
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{


    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"completeTransaction...");
    
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [dele.overlay postImmediateMessage:@"Completing Transaction"  duration:5.0 ];

    
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restoreTransaction...");
    
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [dele.overlay postImmediateMessage:@"Restoring Transaction"  duration:5.0 ];

}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    

    NSLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Transaction error:" message:transaction.error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    [dele.overlay postImmediateErrorMessage:@"Transaction Failed"  duration:5.0 animated:YES];

}
- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Unlocked" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [dele.overlay hideTemporary];

}
- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end

