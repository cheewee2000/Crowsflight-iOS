//
//  cfLocationViewController.h
//  Crowsflight
//
//  Created by Che-Wei Wang on 5/4/13.
//  Copyright (c) 2013 CW&T. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cwtDrawArc.h"
#import "SIAlertView.h"
#import "cwtAppDelegate.h"

#import "cwtArrow.h"

#import <AudioToolbox/AudioToolbox.h>

@interface cfLocationViewController2 : UIViewController<UITextFieldDelegate>{
    cwtAppDelegate* dele;
    
    int bearingAccuracy;

}

@property (nonatomic,strong) IBOutlet UIImageView *arrowImage;
@property (nonatomic,strong)  cwtArrow* arrow;

@property (nonatomic,strong) IBOutlet UIImageView *satSearchImage;


@property (nonatomic,strong) IBOutlet UIButton *destinationButton;
@property (nonatomic,strong) IBOutlet UILabel *distanceText;
@property (nonatomic,strong) IBOutlet UILabel *pageNText;
@property (nonatomic,strong) IBOutlet UILabel *accuracyText;
@property (nonatomic,strong) IBOutlet UILabel *unitText;
@property (nonatomic,strong) IBOutlet  UILabel *displayText;

//@property (nonatomic)   UITextField *nameField;



@property (nonatomic) NSInteger page;
@property (nonatomic) float dlat;
@property (nonatomic) float dlng;
@property (nonatomic) float locBearing;
@property (nonatomic) float distance;
@property (nonatomic) float maxDistance;
@property (nonatomic) float progress;
@property (nonatomic) float spin;
@property (nonatomic) float angle;
@property (nonatomic) float lastAngle;
@property (nonatomic) int spread;
@property (nonatomic) int lastSpread;

@property (nonatomic) BOOL spinning;

-(void)loadLocation;


@property (nonatomic,strong)  cwtDrawArc * arcProgressView;
-(void)updateDestinationName;

-(void)updateDistanceWithLatLng: (float)duration;
- (void)rotateArc:(NSTimeInterval)duration  degrees:(CGFloat)degrees;

- (void)updateHeading;
//- (void)rotateCompass:(NSTimeInterval)duration  degrees:(CGFloat)degrees;
//
//- (IBAction)editLocationName:(id)sender;
-(void)showHideInfo: (float)duration;
//- (void) hideArrow: (BOOL) state;
//-(void) hideCompass:(BOOL) state;

@end
