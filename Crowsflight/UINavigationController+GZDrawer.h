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
 */

#import <UIKit/UIKit.h>

/** DrawerStyle the drawer (and top view controller) layout style. */
typedef enum {
    /** Drawer appears from left and takes the whole screen (the top view controller is fully hidden). A left swipe (for iOS 3.2 and later) will close the drawer. */
    DrawerLayoutStyleLeftFullscreen = 0,
    /** Drawer appears from left but does not take the whole screen. The drawer is anchored on left with the top view partially visible on the right.  A left swipe (for iOS 3.2 and later) or tapping the partially visible top view will close the drawer.
     @see TOP_VIEW_ANCHOR_WIDTH */
    DrawerLayoutStyleLeftAnchored,
    /** Drawer appears from right and takes the whole screen (the top view controller is fully hidden). A right swipe (for iOS 3.2 and later) will close the drawer. */
    DrawerLayoutStyleRightFullscreen,
    /** Drawer appears from right but does not take the whole screen. The drawer is anchored on right with the top view partially visible on the left.  A right swipe (for iOS 3.2 and later) or tapping the partially visible top view will close the drawer.
     @see TOP_VIEW_ANCHOR_WIDTH */
    DrawerLayoutStyleRightAnchored
} DrawerLayoutStyle;

@interface UINavigationController (GZDrawer)

/**
 * Pushes a drawer view controller on the navigation stack.
 * @param viewController the drawer view controller (with menu items, etc.). The root view of the drawer viewcontroller should not be a UIScrollView or subclass thereof.
 * @param style the drawer layout style
 * @param animated if YES, the drawer push is animated. No animation is shown if NO.
 */
- (void) pushDrawerViewController:(UIViewController *)viewController
                        withStyle:(DrawerLayoutStyle)style
                         animated:(BOOL)animated;

/**
 * Pops the top most drawer view controller from the navigation stack. If the top viewcontroller on the navigation stack is not a drawer view controller, then nothing happens.
 * @param animated if YES, the drawer push is animated. No animation is shown if NO.
 */
- (BOOL) popDrawerViewController:(BOOL)animated;

/**
 * Adds the appropriate swipe detection for the desired drawer layout style on the top viewcontroller. The caller is responsible for implementing the selector that would push the drawer with the specified layout style when the swipe event is reported. You are also responsible for removing this gesture recognizer when not needed.
 * @param style the drawer layout style
 * @param target the receiver to be called when the swipe event happens
 * @param selector the selector to be called when the swipe event happens (the selector can take one parameter with UISwipeGestureRecognizer like: -handleSwipe:(UISwipeGestureRecognizer *)swipGesture)
 * @return the gesture recognizer object that was just added (or nil if this iOS version doesn't support gesture recognizers, i.e. iOS 3.1.x and earlier)
 */
- (UISwipeGestureRecognizer *) addSwipeRecognizerForStyle:(DrawerLayoutStyle)style
                                               withTarget:(id)target
                                                 selector:(SEL)selector;

@end