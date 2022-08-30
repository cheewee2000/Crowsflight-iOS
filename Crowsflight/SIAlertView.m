//
//  SIAlertView.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SIAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import "cwtAppDelegate.h"
//#import <W3wSDK/W3wSDK.h>
#import "cwtViewController3.h"


NSString *const SIAlertViewWillShowNotification = @"SIAlertViewWillShowNotification";
NSString *const SIAlertViewDidShowNotification = @"SIAlertViewDidShowNotification";
NSString *const SIAlertViewWillDismissNotification = @"SIAlertViewWillDismissNotification";
NSString *const SIAlertViewDidDismissNotification = @"SIAlertViewDidDismissNotification";

#define DEBUG_LAYOUT 0

#define MESSAGE_MIN_LINE_COUNT 1
#define MESSAGE_MAX_LINE_COUNT 50
#define GAP -5
#define CANCEL_BUTTON_PADDING_TOP 0
#define CONTENT_PADDING_LEFT 0
#define CONTENT_PADDING_TOP 45
#define CONTENT_PADDING_BOTTOM 0
#define BUTTON_HEIGHT 44
#define CONTAINER_WIDTH 320 //replaced with [[UIScreen mainScreen] bounds].size.width
#define BUTTON_TOP_PADDING 40;

@class SIAlertBackgroundWindow;

static NSMutableArray *__si_alert_queue;
static BOOL __si_alert_animating;
static SIAlertBackgroundWindow *__si_alert_background_window;
static SIAlertView *__si_alert_current_view;

@interface SIAlertView ()

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) UIWindow *alertWindow;
@property (nonatomic, assign, getter = isVisible) BOOL visible;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) NSMutableArray *buttons;

@property (nonatomic, assign, getter = isLayoutDirty) BOOL layoutDirty;

@property (nonatomic, strong) CLGeocoder *geo;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;


+ (NSMutableArray *)sharedQueue;
+ (SIAlertView *)currentAlertView;

+ (BOOL)isAnimating;
+ (void)setAnimating:(BOOL)animating;

+ (void)showBackground;
+ (void)hideBackgroundAnimated:(BOOL)animated;

- (void)setup;
- (void)invaliadateLayout;
- (void)resetTransition;

@end


@implementation UITextField (custom)
- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectMake(bounds.origin.x + 40, bounds.origin.y + 10,
                      bounds.size.width - 80, bounds.size.height - 20);
}
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}
@end


#pragma mark - SIBackgroundWindow

@interface SIAlertBackgroundWindow : UIWindow

@end

@interface SIAlertBackgroundWindow ()

@property (nonatomic, assign) SIAlertViewBackgroundStyle style;

@end

@implementation SIAlertBackgroundWindow

- (id)initWithFrame:(CGRect)frame andStyle:(SIAlertViewBackgroundStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        self.style = style;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = NO;
        self.windowLevel = UIWindowLevelAlert;
        
        
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    switch (self.style) {
        case SIAlertViewBackgroundStyleGradient:
        {
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
            CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            break;
        }
        case SIAlertViewBackgroundStyleSolid:
        {
            [[UIColor colorWithWhite:0.1 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
    }
    

    
}

@end

#pragma mark - SIAlertItem

@interface SIAlertItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SIAlertViewButtonType type;
@property (nonatomic, copy) SIAlertViewHandler action;

@end

@implementation SIAlertItem

@end

#pragma mark - SIAlertViewController

@interface SIAlertViewController : UIViewController

@property (nonatomic, strong) SIAlertView *alertView;

@end

@implementation SIAlertViewController

#pragma mark - View life cycle

- (void)loadView
{
    self.view = self.alertView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.alertView setup];
    

    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.alertView resetTransition];
    [self.alertView invaliadateLayout];
}

@end

#pragma mark - SIAlert

@implementation SIAlertView

+ (void)initialize
{
    if (self != [SIAlertView class])
        return;
    
    SIAlertView *appearance = [self appearance];
    appearance.titleColor = [UIColor colorWithWhite:.9 alpha:1];
    appearance.messageColor = [UIColor colorWithWhite:.9 alpha:1];
    appearance.titleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
    appearance.messageFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:8.0f];
    appearance.buttonFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
    appearance.cornerRadius = 0;
    appearance.shadowRadius = 20;
}

- (id)init
{
	return [self initWithTitle:nil andMessage:nil];
}

- (id)initWithTitle:(NSString *)title andMessage:(NSString *)message
{
	self = [super init];
	if (self) {
		_title = title;
        _message = message;
		self.items = [[NSMutableArray alloc] init];
        
        //set styles
        self.topPosition=0;
        //self.containerHeight=104;
        self.transitionStyle=SIAlertViewTransitionStyleSlideFromTop;
        self.backgroundStyle=SIAlertViewBackgroundStyleGradient;
        self.hideBackground=FALSE;

	}
	return self;
}

#pragma mark - Class methods

+ (NSMutableArray *)sharedQueue
{
    if (!__si_alert_queue) {
        __si_alert_queue = [NSMutableArray array];
    }
    return __si_alert_queue;
}

+ (SIAlertView *)currentAlertView
{
    return __si_alert_current_view;
}

+ (void)setCurrentAlertView:(SIAlertView *)alertView
{
    __si_alert_current_view = alertView;
}

+ (BOOL)isAnimating
{
    return __si_alert_animating;
}

+ (void)setAnimating:(BOOL)animating
{
    __si_alert_animating = animating;
}

+ (void)showBackground
{
    
    
    if (!__si_alert_background_window) {
        __si_alert_background_window = [[SIAlertBackgroundWindow alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                                             andStyle:[SIAlertView currentAlertView].backgroundStyle];
        
        
        [__si_alert_background_window makeKeyAndVisible];
        __si_alert_background_window.alpha = 0;
        [UIView animateWithDuration:0.2
                         animations:^{
                             __si_alert_background_window.alpha = 1;
                         }];
        
        
    }
}

-(void)backgroundTouched{
    NSLog(@"background touched");
    [self dismissAnimated:YES];
}

+ (void)hideBackgroundAnimated:(BOOL)animated
{
    if (!animated) {
        [__si_alert_background_window removeFromSuperview];
        __si_alert_background_window = nil;
        return;
    }
    [UIView animateWithDuration:0.2
                     animations:^{
                         __si_alert_background_window.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [__si_alert_background_window removeFromSuperview];
                         __si_alert_background_window = nil;
                     }];
}

#pragma mark - Setters

- (void)setTitle:(NSString *)title
{
    _title = title;
	[self invaliadateLayout];
}

- (void)setMessage:(NSString *)message
{
	_message = message;
    [self invaliadateLayout];
}

#pragma mark - Public

- (void)addButtonWithTitle:(NSString *)title type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler
{
    SIAlertItem *item = [[SIAlertItem alloc] init];
	item.title = title;
	item.type = type;
	item.action = handler;
	[self.items addObject:item];
}

- (void)show
{
    if (![[SIAlertView sharedQueue] containsObject:self]) {
        [[SIAlertView sharedQueue] addObject:self];
    }
    
    if ([SIAlertView isAnimating]) {
        return; // wait for next turn
    }
    
    if (self.isVisible) {
        return;
    }
    
    if ([SIAlertView currentAlertView].isVisible) {
        SIAlertView *alert = [SIAlertView currentAlertView];
        [alert dismissAnimated:YES cleanup:NO];
        return;
    }
    
    if (self.willShowHandler) {
        self.willShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewWillShowNotification object:self userInfo:nil];
    
    self.visible = YES;
    
    [SIAlertView setAnimating:YES];
    [SIAlertView setCurrentAlertView:self];
    
    // transition background
    if(self.hideBackground==FALSE) [SIAlertView showBackground];
    
    
    SIAlertViewController *viewController = [[SIAlertViewController alloc] initWithNibName:nil bundle:nil];
    viewController.alertView = self;
    
    if (!self.alertWindow) {
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        window.opaque = NO;
        window.windowLevel = UIWindowLevelAlert;
        window.rootViewController = viewController;
        self.alertWindow = window;
    }
    [self.alertWindow makeKeyAndVisible];
    
    [self validateLayout];
    
    [self transitionInCompletion:^{
        if (self.didShowHandler) {
            self.didShowHandler(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewDidShowNotification object:self userInfo:nil];
        
        [SIAlertView setAnimating:NO];
        
        NSInteger index = [[SIAlertView sharedQueue] indexOfObject:self];
        if (index < [SIAlertView sharedQueue].count - 1) {
            [self dismissAnimated:YES cleanup:NO]; // dismiss to show next alert view
        }
    }];
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissAnimated:animated cleanup:YES];
}

- (void)dismissAnimated:(BOOL)animated cleanup:(BOOL)cleanup
{
    BOOL isVisible = self.isVisible;
    
    if (isVisible) {
        if (self.willDismissHandler) {
            self.willDismissHandler(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewWillDismissNotification object:self userInfo:nil];
    }
    
    void (^dismissComplete)(void) = ^{
        self.visible = NO;
        
        [self teardown];
        
        [SIAlertView setCurrentAlertView:nil];
        
        SIAlertView *nextAlertView;
        NSInteger index = [[SIAlertView sharedQueue] indexOfObject:self];
        if (index != NSNotFound && index < [SIAlertView sharedQueue].count - 1) {
            nextAlertView = [SIAlertView sharedQueue][index + 1];
        }
        
        if (cleanup) {
            [[SIAlertView sharedQueue] removeObject:self];
        }
        
        [SIAlertView setAnimating:NO];
        
        if (isVisible) {
            if (self.didDismissHandler) {
                self.didDismissHandler(self);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewDidDismissNotification object:self userInfo:nil];
        }
        
        // check if we should show next alert
        if (!isVisible) {
            return;
        }
        
        if (nextAlertView) {
            [nextAlertView show];
        } else {
            // show last alert view
            if ([SIAlertView sharedQueue].count > 0) {
                SIAlertView *alert = [[SIAlertView sharedQueue] lastObject];
                [alert show];
            }
        }
    };
    
    if (animated && isVisible) {
        [SIAlertView setAnimating:YES];
        [self transitionOutCompletion:dismissComplete];
        
        if ([SIAlertView sharedQueue].count == 1) {
            [SIAlertView hideBackgroundAnimated:YES];
        }
        
    } else {
        dismissComplete();
        
        if ([SIAlertView sharedQueue].count == 0) {
            [SIAlertView hideBackgroundAnimated:YES];
        }
    }
    NSLog(@"dismiss SIAlertView");
}

#pragma mark - Transitions

- (void)transitionInCompletion:(void(^)(void))completion
{
    
    switch (self.transitionStyle) {
        case SIAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = self.bounds.size.height;
            
            self.containerView.frame = rect;
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.containerView.frame = originalRect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleSlideFromTop:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = -rect.size.height;
            self.containerView.frame = rect;
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.containerView.frame = originalRect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleFade:
        {
            self.containerView.alpha = 0;
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.containerView.alpha = 1;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleBounce:
        {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.values = @[@(0.01), @(1.2), @(0.9), @(1)];
            animation.keyTimes = @[@(0), @(0.4), @(0.6), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.5;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"bouce"];
        }
            break;
        case SIAlertViewTransitionStyleDropDown:
        {
            CGFloat y = self.containerView.center.y;
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
            animation.values = @[@(y - self.bounds.size.height), @(y + 20), @(y - 10), @(y)];
            animation.keyTimes = @[@(0), @(0.5), @(0.75), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.1;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"dropdown"];
        }
            break;
        default:
            break;
    }
    
    
    
}

- (void)transitionOutCompletion:(void(^)(void))completion
{
    switch (self.transitionStyle) {
        case SIAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = self.bounds.size.height;
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.frame = rect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleSlideFromTop:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = -rect.size.height;
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.frame = rect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleFade:
        {
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.containerView.alpha = 0;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleBounce:
        {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.values = @[@(1), @(1.2), @(0.01)];
            animation.keyTimes = @[@(0), @(0.4), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.35;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"bounce"];
            
            self.containerView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }
            break;
        case SIAlertViewTransitionStyleDropDown:
        {
            CGPoint point = self.containerView.center;
            point.y += self.bounds.size.height;
            [UIView animateWithDuration:0.2
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.center = point;
                                 CGFloat angle = ((CGFloat)arc4random_uniform(100) - 50.f) / 100.f;
                                 self.containerView.transform = CGAffineTransformMakeRotation(angle);
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        default:
            break;
    }
}

- (void)resetTransition
{
    [self.containerView.layer removeAllAnimations];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self validateLayout];
}

- (void)invaliadateLayout
{
    self.layoutDirty = YES;
    [self setNeedsLayout];
}

- (void)validateLayout
{
    if (!self.isLayoutDirty) {
        return;
    }
    self.layoutDirty = NO;
#if DEBUG_LAYOUT
    NSLog(@"%@, %@", self, NSStringFromSelector(_cmd));
#endif
    
    CGFloat height = [self preferredHeight];
    //CGFloat height = self.containerHeight;
    CGFloat left = (self.bounds.size.width - [[UIScreen mainScreen] bounds].size.width) * 0.5;
    //CGFloat top = (self.bounds.size.height - height) * 0.5;
    CGFloat top=self.topPosition;
    
    self.containerView.transform = CGAffineTransformIdentity;
    self.containerView.frame = CGRectMake(left, top, [[UIScreen mainScreen] bounds].size.width, height);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds cornerRadius:self.containerView.layer.cornerRadius].CGPath;
    
    CGFloat y = CONTENT_PADDING_TOP;
	if (self.titleLabel) {
        self.titleLabel.text = self.title;
        CGFloat height = [self heightForTitleLabel];
        self.titleLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
	}
    if (self.messageLabel) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        self.messageLabel.text = self.message;
        CGFloat height = [self heightForMessageLabel];
        self.messageLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
    }
    if (self.items.count > 0) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
            if (self.items.count == 2) {

                CGFloat width = (self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2 - GAP) * 0.5;
                UIButton *button = self.buttons[0];
                button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, width, BUTTON_HEIGHT);
                button = self.buttons[1];
                button.frame = CGRectMake(CONTENT_PADDING_LEFT + width + GAP, y, width, BUTTON_HEIGHT);
            } else {
                
                //force OK button position
                //y=60;
                
                for (NSUInteger i = 0; i < self.buttons.count; i++) {
                    if ( ((SIAlertItem *)self.items[i]).type!=SIAlertViewButtonTypeCancel)
                    {

                        UIButton *button = self.buttons[i];
                        button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, BUTTON_HEIGHT);
                        if (self.buttons.count > 1) {
                            if (i == self.buttons.count - 1 && ((SIAlertItem *)self.items[i]).type == SIAlertViewButtonTypeCancel) {
                                CGRect rect = button.frame;
                                rect.origin.y += CANCEL_BUTTON_PADDING_TOP;
                                button.frame = rect;
                            }
                            y += BUTTON_HEIGHT + GAP;
                        }
                        
                        
                    }
                    //cancel button
                    else{
                        UIButton *button = self.buttons[i];
                        button.frame=CGRectMake(280, 5, 30, 30);
                    }
            }
        }
    }
}

- (CGFloat)preferredHeight
{
	CGFloat height = CONTENT_PADDING_TOP;
	if (self.title) {
		height += [self heightForTitleLabel];
	}
    if (self.message) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += [self heightForMessageLabel];
    }
    if (self.items.count > 0) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        if (self.items.count <= 2) {
            height += BUTTON_HEIGHT;
        } else {
            height += (BUTTON_HEIGHT + GAP) * self.items.count - GAP;
            if (self.buttons.count > 2 && ((SIAlertItem *)[self.items lastObject]).type == SIAlertViewButtonTypeCancel) {
                height += CANCEL_BUTTON_PADDING_TOP;
            }
        }
    }
    
    if(self.textField){
        height+=42;
        
    }
    height += CONTENT_PADDING_BOTTOM;
	return height;
}

- (CGFloat)heightForTitleLabel
{
    if (self.titleLabel) {
//        CGSize size = [self.title sizeWithFont:self.titleLabel.font
//                                   minFontSize:self.titleLabel.font.pointSize * self.titleLabel.minimumScaleFactor
//                                actualFontSize:nil
//                                      forWidth:[[UIScreen mainScreen] bounds].size.width - CONTENT_PADDING_LEFT * 2
//                                 lineBreakMode:self.titleLabel.lineBreakMode];
//        
    
        
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        
        paragraphStyle.lineBreakMode=self.titleLabel.lineBreakMode;
        NSDictionary *attributes = @{ NSFontAttributeName: self.titleLabel.font,
                                      NSParagraphStyleAttributeName: paragraphStyle };
        
        
        CGSize size = [self.title sizeWithAttributes:attributes];
        
        
        return size.height;
    }
    return 0;
}

- (CGFloat)heightForMessageLabel
{
    CGFloat minHeight = MESSAGE_MIN_LINE_COUNT * self.messageLabel.font.lineHeight;
    if (self.messageLabel) {
//        CGFloat maxHeight = MESSAGE_MAX_LINE_COUNT * self.messageLabel.font.lineHeight;
//        CGSize size = [self.message sizeWithFont:self.messageLabel.font
//                               constrainedToSize:CGSizeMake([[UIScreen mainScreen] bounds].size.width - CONTENT_PADDING_LEFT * 2, maxHeight)
//                                   lineBreakMode:self.messageLabel.lineBreakMode];
//        
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        
        paragraphStyle.lineBreakMode=self.messageLabel.lineBreakMode;
        NSDictionary *attributes = @{ NSFontAttributeName: self.messageLabel.font,
                                      NSParagraphStyleAttributeName: paragraphStyle };
        
        
        CGSize size = [self.message sizeWithAttributes:attributes];
        
        
        return MAX(minHeight, size.height*2.1);
        //return size.height*5;

    }
    return minHeight;
}

#pragma mark - Setup

- (void)setup
{
    [self setupContainerView];
    [self updateTitleLabel];
    [self updateMessageLabel];
    [self setupButtons];
    [self invaliadateLayout];
}

- (void)teardown
{
    [self.containerView removeFromSuperview];
    self.containerView = nil;
    self.titleLabel = nil;
    self.messageLabel = nil;
    [self.buttons removeAllObjects];
    [self.alertWindow removeFromSuperview];
    self.alertWindow = nil;
}

- (void)setupContainerView
{
    //background button to cancel alertview
    if(self.hideBackground==FALSE){
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self
                   action:@selector(backgroundTouched)
         forControlEvents:UIControlEventTouchDown];
        [button setTitle:@"" forState:UIControlStateNormal];
    
        CGRect screen = [[UIScreen mainScreen] bounds];
        
        button.frame = CGRectMake(0,0,screen.size.width,screen.size.height);
        
        [self addSubview:button];
    }
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    
    self.containerView.backgroundColor = [UIColor colorWithRed:1.0f green:78.0/255.0f blue:36.0/255.0f alpha:1];
    self.containerView.layer.cornerRadius = self.cornerRadius;
    self.containerView.layer.shadowOffset = CGSizeZero;
    self.containerView.layer.shadowRadius = self.shadowRadius;
    self.containerView.layer.shadowOpacity = 0.5;


    [self addSubview:self.containerView];

    if(self.showTextField) [self addSearchField];
    if(self.showSpinner) [self addSpinner];

}


-(void)addSearchField{
    
    cwtAppDelegate* dele=[[UIApplication sharedApplication] delegate];
    CGRect screen = [[UIScreen mainScreen] applicationFrame];

    CGFloat height = [self preferredHeight];

    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, height*2+30, screen.size.width, 44)];
    [ self.textField  setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
    self.textField .autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.textField .autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
    

    if([self.keyboardGo isEqual:@"DONE"]){
        self.textField .returnKeyType=UIReturnKeyDone;
        [self.textField  setText:@""];
    }
    
    else if([self.keyboardGo isEqual:@"SEARCH"]){
        self.textField .returnKeyType=UIReturnKeySearch;
        [self.textField  setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"lastSearchText"]];

    }

    //add current location
    else if([self.keyboardGo isEqual:@"ADD"]) {
        self.textField .returnKeyType=UIReturnKeyGo;
        [self.textField  setText:@""];

        
        __block NSString *locTitle=[[NSString alloc] init];
        locTitle=@"";
        

        
        if(dele.hasInternet)
        {
            [ self.textField  setPlaceholder:@"LOADING LOCATION NAME..."];

            self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.spinner.frame=CGRectMake(10, 10, 44, 44);
            self.spinner.hidesWhenStopped = YES;

            [self.textField  setLeftView:self.spinner];
            [self.textField  setLeftViewMode:UITextFieldViewModeAlways];

            [self.spinner startAnimating];
         
            //reverse geocode
            self.geo=[[CLGeocoder alloc] init];
            CLLocation *loc=[[CLLocation alloc] initWithLatitude:dele.myLat longitude:dele.myLng];
            
            
            [self.geo reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
                
                [self.spinner stopAnimating];
                [ self.textField  setPlaceholder:@""];

                if([placemarks count]>0){
                    CLPlacemark  *placemark=[[CLPlacemark alloc] initWithPlacemark:[placemarks objectAtIndex:0]];
                    locTitle=placemark.name;
                    locTitle=[locTitle uppercaseString];
                    if(locTitle.length>0) self.textField.text=locTitle;
                }                

            }];
        }
    
        else{
            
            cwtAppDelegate * dele = [[UIApplication sharedApplication] delegate];
            //W3wPosition *tPosition = [dele.viewController.w3wSDK convertPositionToW3W:kW3wLanguageEnglish lat:dele.myLat lng:dele.myLng];
            //self.textField.text=[NSString stringWithFormat:@"%f,%f %@",dele.myLat,dele.myLng,tPosition.getW3w];

            self.textField.text=[NSString stringWithFormat:@"%f,%f",dele.myLat,dele.myLng];
        }
        

        
    }
    
    self.textField .clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
    self.textField .borderStyle = UITextBorderStyleNone;
    self.textField .layer.masksToBounds=YES;

    [self.textField setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f]];
    
     self.textField .delegate=(id)dele.viewController;
     self.textField .tag=self.textFieldTag;

    [self.textField setTextColor:[UIColor colorWithWhite:.1 alpha:1]];

    [self.textField  becomeFirstResponder];
    [self.containerView addSubview: self.textField ];
}

-(void)cancelGeo{
    [self.spinner stopAnimating];
    [self.geo cancelGeocode];
}


-(void)addSpinner{
//    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//    spinner.center = CGPointMake(160, 70);
//    spinner.hidesWhenStopped = YES;
//    
//    [spinner startAnimating];

    CGRect screen = [[UIScreen mainScreen] bounds];

    self.progressPie = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    self.progressPie.center=CGPointMake(screen.size.width/2.0, 150);
    self.progressPie.animationImages = [NSArray arrayWithObjects:
                                        [UIImage imageNamed:@"loading-1.png"],
                                        [UIImage imageNamed:@"loading-2.png"],
                                        [UIImage imageNamed:@"loading-3.png"],
                                        [UIImage imageNamed:@"loading-4.png"],
                                        [UIImage imageNamed:@"loading-5.png"],
                                        [UIImage imageNamed:@"loading-6.png"],
                                        [UIImage imageNamed:@"loading-7.png"],
                                        [UIImage imageNamed:@"loading-8.png"],
                                        [UIImage imageNamed:@"loading-9.png"],
                                        [UIImage imageNamed:@"loading-10.png"],
                                        [UIImage imageNamed:@"loading-11.png"],
                                        [UIImage imageNamed:@"loading-12.png"],
                                        [UIImage imageNamed:@"loading-13.png"],
                                        [UIImage imageNamed:@"loading-14.png"],
                                        [UIImage imageNamed:@"loading-15.png"],
                                        [UIImage imageNamed:@"loading-16.png"],
                                        [UIImage imageNamed:@"loading-17.png"],
                                        [UIImage imageNamed:@"loading-18.png"],
                                        [UIImage imageNamed:@"loading-19.png"],
                                        [UIImage imageNamed:@"loading-20.png"],
                                        [UIImage imageNamed:@"loading-21.png"],
                                        [UIImage imageNamed:@"loading-22.png"],
                                        [UIImage imageNamed:@"loading-23.png"],
                                        [UIImage imageNamed:@"loading-24.png"],

                                        nil];
    self.progressPie.animationDuration = 2.0f;
    self.progressPie.animationRepeatCount = 0;
    [self.progressPie startAnimating];
    
    
    [self.containerView addSubview:self.progressPie];
    
    
}

- (void)updateTitleLabel
{
	if (self.title) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.backgroundColor = [UIColor clearColor];
			self.titleLabel.font = self.titleFont;
            self.titleLabel.textColor = self.titleColor;
            self.titleLabel.adjustsFontSizeToFitWidth = YES;
            self.titleLabel.minimumScaleFactor = 0.75;
			[self.containerView addSubview:self.titleLabel];
#if DEBUG_LAYOUT
            self.titleLabel.backgroundColor = [UIColor redColor];
#endif
		}
		self.titleLabel.text = self.title;
	} else {
		[self.titleLabel removeFromSuperview];
		self.titleLabel = nil;
	}
    [self invaliadateLayout];
}

- (void)updateMessageLabel
{
    if (self.message) {
        if (!self.messageLabel) {
            self.messageLabel = [[UILabel alloc] initWithFrame:self.bounds];
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.font = self.messageFont;
            self.messageLabel.textColor = self.messageColor;
            self.messageLabel.numberOfLines = MESSAGE_MAX_LINE_COUNT;
            [self.containerView addSubview:self.messageLabel];
#if DEBUG_LAYOUT
            self.messageLabel.backgroundColor = [UIColor redColor];
#endif
        }
        self.messageLabel.text = [self.message uppercaseString];
    } else {
        [self.messageLabel removeFromSuperview];
        self.messageLabel = nil;
    }
    [self invaliadateLayout];
}

- (void)setupButtons
{
    self.buttons = [[NSMutableArray alloc] initWithCapacity:self.items.count];
    for (NSUInteger i = 0; i < self.items.count; i++) {
        UIButton *button = [self buttonForItemIndex:i];
        [self.buttons addObject:button];
        [self.containerView addSubview:button];
        
        
    }
}

- (UIButton *)buttonForItemIndex:(NSUInteger)index
{
    SIAlertItem *item = self.items[index];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.tag = index;
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.titleLabel.font = self.buttonFont;
    
	[button setTitle:item.title forState:UIControlStateNormal];
	UIImage *normalImage = nil;
	UIImage *highlightedImage = nil;
	switch (item.type) {
		case SIAlertViewButtonTypeCancel:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-cancel"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-cancel-d"];
			[button setTitleColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateHighlighted];
            
            button.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: 20.0f];
			break;
		case SIAlertViewButtonTypeDestructive:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-destructive"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-destructive-d"];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateHighlighted];
			break;
		case SIAlertViewButtonTypeDefault:
		default:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default-d"];
			[button setTitleColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateHighlighted];
			break;
	}
    
	CGFloat hInset = floorf(normalImage.size.width / 2);
	CGFloat vInset = floorf(normalImage.size.height / 2);
	UIEdgeInsets insets = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
	normalImage = [normalImage resizableImageWithCapInsets:insets];
	highlightedImage = [highlightedImage resizableImageWithCapInsets:insets];
	[button setBackgroundImage:normalImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    
	[button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark - Actions

- (void)buttonAction:(UIButton *)button
{
	[SIAlertView setAnimating:YES]; // set this flag to YES in order to prevent showing another alert in action block
    SIAlertItem *item = self.items[button.tag];
	if (item.action) {
		item.action(self);
	}
	[self dismissAnimated:YES];
}

#pragma mark - CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    void(^completion)(void) = [anim valueForKey:@"handler"];
    if (completion) {
        completion();
    }
}

#pragma mark - UIAppearance setters

- (void)setTitleFont:(UIFont *)titleFont
{
    if (_titleFont == titleFont) {
        return;
    }
    _titleFont = titleFont;
    self.titleLabel.font = titleFont;
    [self invaliadateLayout];
}

- (void)setMessageFont:(UIFont *)messageFont
{
    if (_messageFont == messageFont) {
        return;
    }
    _messageFont = messageFont;
    self.messageLabel.font = messageFont;
    [self invaliadateLayout];
}

- (void)setTitleColor:(UIColor *)titleColor
{
    if (_titleColor == titleColor) {
        return;
    }
    _titleColor = titleColor;
    self.titleLabel.textColor = titleColor;
}

- (void)setMessageColor:(UIColor *)messageColor
{
    if (_messageColor == messageColor) {
        return;
    }
    _messageColor = messageColor;
    self.messageLabel.textColor = messageColor;
}

- (void)setButtonFont:(UIFont *)buttonFont
{
    if (_buttonFont == buttonFont) {
        return;
    }
    _buttonFont = buttonFont;
    for (UIButton *button in self.buttons) {
        button.titleLabel.font = buttonFont;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    self.containerView.layer.cornerRadius = cornerRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    if (_shadowRadius == shadowRadius) {
        return;
    }
    _shadowRadius = shadowRadius;
    self.containerView.layer.shadowRadius = shadowRadius;
}

@end
