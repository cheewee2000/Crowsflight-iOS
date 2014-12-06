/**
 * Copyright (c) 2013 Ephraim Tekle genzeb@gmail.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
 * following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 * LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
 * NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#import "UINavigationController+GZDrawer.h"
#import <QuartzCore/QuartzCore.h>
#import "cwtAppDelegate.h"

/** Modify this number to change how much of the top view is still visible when drawer layout is anchored */
#define TOP_VIEW_ANCHOR_WIDTH 40
/** The view tag used (in drawer view controller's view) to identify view controllers as drawers */
#define TOP_VIEW_TAG 99999
/** The shadow radius when drawer style is anchored */
#define TOP_VIEW_SHADOW_RADIUS 10.0
/** The shadow opacity when drawer style is anchored */
#define TOP_VIEW_SHADOW_OPACITY 0.5

@implementation UINavigationController (GZDrawer)

// Screencapture a view and turn it into an image
+ (UIImage *)imageByScreencapturingView:(UIView *)view {
    
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0.0);
    } else    {
        UIGraphicsBeginImageContext(view.bounds.size);
    }
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

// The status bar frame wrt a view
+ (CGRect)statusBarFrameWithView:(UIView*)view {
    return [view convertRect:[view.window convertRect:[[UIApplication sharedApplication] statusBarFrame]
                                           fromWindow:nil]
                    fromView:nil];
}

// A shortcut for poping the currnent drawer
- (void)popDrawerViewController {
    [self popDrawerViewController:YES];
}

- (UISwipeGestureRecognizer *) addSwipeRecognizerForStyle:(DrawerLayoutStyle)style withTarget:(id)target selector:(SEL)selector {
    
    if (NSClassFromString (@"UISwipeGestureRecognizer")) {
        
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:target action:selector];
        
        switch (style) {
            case DrawerLayoutStyleLeftFullscreen:
            case DrawerLayoutStyleLeftAnchored:
                swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
                break;
            case DrawerLayoutStyleRightFullscreen:
            case DrawerLayoutStyleRightAnchored:
                swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
                break;
        }
        
        [self.topViewController.view addGestureRecognizer:swipeGesture];
        
    }
    
    return nil;
}

- (void) pushDrawerViewController:(UIViewController *)viewController
                        withStyle:(DrawerLayoutStyle)style
                         animated:(BOOL)animated {
    
    // Screen capture the current content of the navigation view (alogn with the navigation bar, if any)
    UIImage *image = [[self class] imageByScreencapturingView:self.view.window];
    
    CGRect frame = self.view.window.bounds;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        
    }else{
        frame.origin.y -= [[self class] statusBarFrameWithView:self.view].size.height;
    }
    

    // Create  button with the screen capture
    UIButton *topViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    topViewButton.frame = frame;
    topViewButton.adjustsImageWhenHighlighted=NO;
    [topViewButton setImage:image forState:UIControlStateNormal];
    topViewButton.tag = TOP_VIEW_TAG;
    topViewButton.layer.shadowOffset = CGSizeZero;
    topViewButton.layer.shadowRadius = TOP_VIEW_SHADOW_RADIUS;
    topViewButton.layer.shadowColor = [UIColor blackColor].CGColor;
    topViewButton.layer.shadowOpacity = TOP_VIEW_SHADOW_OPACITY;
    topViewButton.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.window.layer.bounds].CGPath;
    // Tapping the button closes the drawer
    [topViewButton addTarget:self action:@selector(popDrawerViewController) forControlEvents:UIControlEventTouchDown];
    // Add the button to the drawer view controller
    [viewController.view addSubview:topViewButton];
    
    // Add a left-swipe guesture recognizer to the drawer if available
//    if (NSClassFromString (@"UISwipeGestureRecognizer")) {
//        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(popDrawerViewController)];
//        switch (style) {
//            case DrawerLayoutStyleLeftFullscreen:
//            case DrawerLayoutStyleLeftAnchored:
//                swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
//                break;
//            case DrawerLayoutStyleRightFullscreen:
//            case DrawerLayoutStyleRightAnchored:
//                swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
//                break;
//        }
//        [viewController.view addGestureRecognizer:swipeGesture];
//    }
    
    viewController.hidesBottomBarWhenPushed = YES;
    
    
    // Make the drawer visible but overlayed with the screen capture
    [self setNavigationBarHidden:YES animated:NO];
    [self pushViewController:viewController animated:NO];
    
    // Animate screen capture out of the way as desired
    switch (style) {
        case DrawerLayoutStyleLeftFullscreen:
            frame.origin.x = frame.size.width + TOP_VIEW_SHADOW_RADIUS;
            break;
        case DrawerLayoutStyleLeftAnchored:
            frame.origin.x = frame.size.width - TOP_VIEW_ANCHOR_WIDTH;
            break;
        case DrawerLayoutStyleRightFullscreen:
            frame.origin.x =  TOP_VIEW_SHADOW_RADIUS - frame.size.width;
            break;
        case DrawerLayoutStyleRightAnchored:
            frame.origin.x = TOP_VIEW_ANCHOR_WIDTH - frame.size.width;
            break;
    }
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.15];
    }
    
    
    topViewButton.frame = frame;
    

    if (animated) {
        [UIView commitAnimations];
    }
}

- (void) popDrawerAnimationDidEnd {
    UIView *topView = [self.topViewController.view viewWithTag:TOP_VIEW_TAG];
    
    [self setNavigationBarHidden:YES animated:NO];
    [self popViewControllerAnimated:NO];
    [topView removeFromSuperview];
}

- (BOOL) popDrawerViewController:(BOOL)animated {
    
    UIView *topView = [self.topViewController.view viewWithTag:TOP_VIEW_TAG];
    
    

    //cwtAppDelegate* dele= [[UIApplication sharedApplication] delegate];
    //UIView *topView = [self.topViewController.view viewWithTag:333];

    if (!topView) {
        return NO;
    }
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.15];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(popDrawerAnimationDidEnd)];
                
        
//        [UIView animateWithDuration:.2
//                              delay:0
//                            options:UIViewAnimationOptionAllowUserInteraction
//                         animations:^{
//                             CGRect frame = topView.frame;
//                                  frame.origin.x = 0;
//                              topView.frame = frame;
//                             
// 
//                             
//                         }
//                         completion:^(BOOL finished) {
//                             [UIView animateWithDuration:.2
//                                                   delay:0
//                                                 options:UIViewAnimationOptionAllowUserInteraction
//                                              animations:^{
//                                                 [topView setAlpha:0];
//                                              }
//                                              completion:^(BOOL finished) {
//                                                  [self popDrawerAnimationDidEnd];
//                                              }];                         }];
//        
//        
    }
    
    CGRect frame = topView.frame;
    frame.origin.x = 0;

    topView.frame = frame;
    //[topView setAlpha:0.5];
    
    if (animated) {
        [UIView commitAnimations];
    } else {
        [self popDrawerAnimationDidEnd];
    }
    
    return YES;
}

@end